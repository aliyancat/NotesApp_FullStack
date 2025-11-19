// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/models/friend_request_model.dart';
import 'dart:io';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user ID and email
  static String? get currentUserId => _auth.currentUser?.uid;
  static String? get currentUserEmail => _auth.currentUser?.email;

  // ============================================================================
  // USERNAME AND VALIDATION METHODS
  // ============================================================================

  /// Check if username is available (excluding current user)
  Future<bool> isUsernameAvailable(
    String username, [
    String? excludeUserId,
  ]) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();

      // Username validation
      if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(normalizedUsername)) {
        return false;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: normalizedUsername)
          .get();

      if (querySnapshot.docs.isEmpty) return true;

      // If excluding current user, check if the found user is the excluded one
      if (excludeUserId != null &&
          querySnapshot.docs.first.id == excludeUserId) {
        return true;
      }

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  /// Find user by username
  Future<UserModel?> findUserByUsername(String username) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();

      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: normalizedUsername)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return UserModel.fromMap({...doc.data(), 'id': doc.id});
    } catch (e) {
      print('Error finding user by username: $e');
      return null;
    }
  }

  /// Find user by email
  Future<UserModel?> findUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return UserModel.fromMap({...doc.data(), 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error finding user by email: $e');
      return null;
    }
  }

  /// Get user profile by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }


  // ============================================================================
  // PROFILE MANAGEMENT METHODS
  // ============================================================================

  /// Upload profile picture
  Future<String?> uploadProfilePicture(File imageFile, String userId) async {
    try {
      // Delete existing image first
      await _deleteProfileImage(userId);

      final storageRef = _storage
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  /// Delete profile picture
  Future<void> deleteProfilePicture(String userId) async {
    await _deleteProfileImage(userId);
  }

  /// Internal method to delete profile image from Firebase Storage
  Future<void> _deleteProfileImage(String userId) async {
    try {
      final storageRef = _storage
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      await storageRef.delete();
    } catch (e) {
      // Ignore if file doesn't exist
      if (!e.toString().contains('object-not-found')) {
        print('Error deleting profile picture: $e');
      }
    }
  }

  /// Update user profile with comprehensive validation and image handling
  Future<void> updateUserProfile({
    String? displayName,
    String? username,
    DateTime? birthDate,
    bool? showBirthDate,
    bool? showOnlineStatus,
    String? photoUrl,
    bool? profileCompleted,
    String? bio,
    File? profileImage,
    bool? removeImage = false,
  }) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      Map<String, dynamic> updates = {};

      // Validate and update display name
      if (displayName != null) {
        if (displayName.trim().isEmpty) {
          throw Exception('Display name cannot be empty');
        }
        if (displayName.trim().length < 2) {
          throw Exception('Display name must be at least 2 characters');
        }
        if (displayName.trim().length > 50) {
          throw Exception('Display name must be less than 50 characters');
        }
        updates['displayName'] = displayName.trim();
      }

      // Validate and update username
      if (username != null) {
        final normalizedUsername = username.toLowerCase().trim();

        if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(normalizedUsername)) {
          throw Exception(
            'Username can only contain letters, numbers, and underscores (3-30 characters)',
          );
        }

        final isAvailable = await isUsernameAvailable(
          normalizedUsername,
          currentUserId,
        );
        if (!isAvailable) {
          throw Exception('Username @$normalizedUsername is not available');
        }
        updates['username'] = normalizedUsername;
      }

      // Validate and update bio
      if (bio != null) {
        if (bio.length > 150) {
          throw Exception('Bio must be less than 150 characters');
        }
        updates['bio'] = bio.trim();
        updates['lastBioUpdate'] = FieldValue.serverTimestamp();
      }

      // Handle other profile fields
      if (birthDate != null) {
        final age = _calculateAge(birthDate);
        if (age < 16) {
          throw Exception('You must be at least 16 years old to use this app');
        }
        updates['birthDate'] = Timestamp.fromDate(birthDate);
      }

      if (showBirthDate != null) updates['showBirthDate'] = showBirthDate;
      if (showOnlineStatus != null)
        updates['showOnlineStatus'] = showOnlineStatus;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (profileCompleted != null)
        updates['profileCompleted'] = profileCompleted;

      // Handle profile image
      if (profileImage != null) {
        final imageUrl = await uploadProfilePicture(
          profileImage,
          currentUserId!,
        );
        if (imageUrl != null) {
          updates['photoUrl'] = imageUrl;
        }
      } else if (removeImage == true) {
        await deleteProfilePicture(currentUserId!);
        updates['photoUrl'] = FieldValue.delete();
      }

      updates['lastSeen'] = FieldValue.serverTimestamp();

      // Update Firestore document
      await _firestore.collection('users').doc(currentUserId).update(updates);

      // Update Firebase Auth profile if needed
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        if (displayName != null) {
          await currentUser.updateDisplayName(displayName.trim());
        }
        if (profileImage != null && updates.containsKey('photoUrl')) {
          await currentUser.updatePhotoURL(updates['photoUrl']);
        } else if (removeImage == true) {
          await currentUser.updatePhotoURL(null);
        }
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Validate profile data before saving
  Map<String, String?> validateProfileData({
    required String displayName,
    required String username,
    required String bio,
  }) {
    Map<String, String?> errors = {};

    // Validate display name
    if (displayName.trim().isEmpty) {
      errors['displayName'] = 'Display name is required';
    } else if (displayName.trim().length < 2) {
      errors['displayName'] = 'Display name must be at least 2 characters';
    } else if (displayName.trim().length > 50) {
      errors['displayName'] = 'Display name must be less than 50 characters';
    }

    // Validate username
    if (username.trim().isEmpty) {
      errors['username'] = 'Username is required';
    } else if (username.trim().length < 3) {
      errors['username'] = 'Username must be at least 3 characters';
    } else if (username.trim().length > 30) {
      errors['username'] = 'Username must be less than 30 characters';
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username.trim())) {
      errors['username'] =
          'Username can only contain letters, numbers, and underscores';
    }

    // Validate bio
    if (bio.length > 150) {
      errors['bio'] = 'Bio must be less than 150 characters';
    }

    return errors;
  }

  /// Get profile completion percentage
  int getProfileCompletionPercentage(UserModel user) {
    int completed = 0;
    const int totalFields = 6;

    if (user.displayName.isNotEmpty) completed++;
    if (user.username.isNotEmpty) completed++;
    if (user.bio?.isNotEmpty == true) completed++;
    if (user.photoUrl != null) completed++;
    if (user.email.isNotEmpty) completed++;
    if (user.birthDate != null) completed++;

    return ((completed / totalFields) * 100).round();
  }

  /// Check if user profile is completed
  Future<bool> isProfileCompleted() async {
    if (currentUserId == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      if (!doc.exists) return false;

      final userData = UserModel.fromMap({...doc.data()!, 'id': doc.id});
      return userData.profileCompleted &&
          userData.birthDate != null &&
          userData.meetsAgeRequirement;
    } catch (e) {
      print('Error checking profile completion: $e');
      return false;
    }
  }

  /// Create user profile with comprehensive validation
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String displayName,
    required String username,
    String? photoUrl,
    DateTime? birthDate,
    String? bio,
  }) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();

      // Validate display name
      if (displayName.trim().isEmpty || displayName.trim().length < 2) {
        throw Exception('Display name must be at least 2 characters');
      }

      // Double-check username availability
      final isAvailable = await isUsernameAvailable(normalizedUsername);
      if (!isAvailable) {
        throw Exception('Username is not available');
      }

      // Validate age if birth date is provided
      bool profileCompleted = false;
      if (birthDate != null) {
        final age = _calculateAge(birthDate);
        if (age < 16) {
          throw Exception('You must be at least 16 years old to use this app');
        }
        profileCompleted = true;
      }

      final userModel = UserModel(
        id: userId,
        email: email.toLowerCase(),
        displayName: displayName.trim(),
        username: normalizedUsername,
        photoUrl: photoUrl,
        lastSeen: DateTime.now(),
        isOnline: true,
        friends: [],
        birthDate: birthDate,
        showBirthDate: false,
        showOnlineStatus: true,
        profileCompleted: profileCompleted,
        bio: bio?.trim(),
      );

      await _firestore.collection('users').doc(userId).set(userModel.toMap());
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  // ============================================================================
  // USER STATUS AND ACTIVITY METHODS
  // ============================================================================

  /// Update user's online status (respects privacy settings)
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  /// Get user activity status
  Future<Map<String, dynamic>> getUserActivityStatus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return {};

      final userData = userDoc.data()!;
      final lastSeen = (userData['lastSeen'] as Timestamp?)?.toDate();
      final isOnline = userData['isOnline'] ?? false;

      return {
        'isOnline': isOnline,
        'lastSeen': lastSeen,
        'status': _getActivityStatus(isOnline, lastSeen),
      };
    } catch (e) {
      print('Error getting user activity status: $e');
      return {};
    }
  }

  /// Get formatted activity status string
  String _getActivityStatus(bool isOnline, DateTime? lastSeen) {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Unknown';

    final difference = DateTime.now().difference(lastSeen);

    if (difference.inMinutes < 5) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return 'Long time ago';
  }

  /// Update user verification status (admin only)
  Future<void> updateVerificationStatus(String userId, bool isVerified) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': isVerified,
      });
    } catch (e) {
      throw Exception('Failed to update verification status: $e');
    }
  }

  /// Bulk update user preferences
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      if (currentUserId == null) throw Exception('No authenticated user');

      await _firestore.collection('users').doc(currentUserId).update({
        'preferences': preferences,
        'preferencesUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update preferences: $e');
    }
  }

  // ============================================================================
  // CURRENT USER METHODS
  // ============================================================================

  /// Get current user stream
  Stream<UserModel?> getCurrentUserStream() {
    if (currentUserId == null) return Stream.value(null);

    return _firestore.collection('users').doc(currentUserId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return UserModel.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    });
  }

  /// Get current user data
  Future<UserModel?> getCurrentUser() async {
    if (currentUserId == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      if (doc.exists) {
        return UserModel.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // ============================================================================
  // FRIEND REQUEST METHODS
  // ============================================================================

  /// Send friend request by username
  Future<bool> sendFriendRequest(String username) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return false;
      }

      final normalizedUsername = username.toLowerCase().trim();

      // Find the user by username
      final receiverUser = await findUserByUsername(normalizedUsername);
      if (receiverUser == null) {
        return false;
      }

      // Check if user is trying to add themselves
      if (receiverUser.id == currentUser.uid) {
        throw Exception('You cannot send a friend request to yourself');
      }

      // Get current user data
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!currentUserDoc.exists) {
        return false;
      }

      final currentUserData = UserModel.fromMap({
        ...currentUserDoc.data()!,
        'id': currentUserDoc.id,
      });

      // Check if already friends
      if (currentUserData.friends.contains(receiverUser.id)) {
        throw Exception('User is already in your friends list');
      }

      // Check if there's mutual blocking
      final canInteract = await canInteractWithUser(receiverUser.id);
      if (!canInteract) {
        throw Exception('Cannot send friend request to this user');
      }

      // Check if there's already a pending request
      final existingRequest = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: currentUser.uid)
          .where('receiverId', isEqualTo: receiverUser.id)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingRequest.docs.isNotEmpty) {
        throw Exception('Friend request already sent');
      }

      // Check if there's a pending request from the other user
      final reverseRequest = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: receiverUser.id)
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (reverseRequest.docs.isNotEmpty) {
        throw Exception(
          'This user has already sent you a friend request. Check your incoming requests!',
        );
      }

      // Create friend request
      final requestId = _firestore.collection('friendRequests').doc().id;
      final friendRequest = FriendRequestModel(
        id: requestId,
        senderId: currentUser.uid,
        receiverId: receiverUser.id,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .set(friendRequest.toMap());

      return true;
    } catch (e) {
      print('Error sending friend request: $e');
      rethrow;
    }
  }

  /// Get incoming friend requests stream
  Stream<List<Map<String, dynamic>>> getIncomingFriendRequestsStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> requestsWithUserData = [];

          for (var doc in snapshot.docs) {
            try {
              final request = FriendRequestModel.fromMap(
                doc.data(),
                docId: doc.id,
              );

              // Get sender's user data
              final senderDoc = await _firestore
                  .collection('users')
                  .doc(request.senderId)
                  .get();

              if (senderDoc.exists) {
                final senderData = senderDoc.data()!;
                senderData['id'] = senderDoc.id;

                final senderUser = UserModel.fromMap(senderData);

                requestsWithUserData.add({
                  'id': request.id,
                  'fromUser': senderUser.toMap(),
                });
              }
            } catch (e) {
              // Silently skip invalid requests
            }
          }

          return requestsWithUserData;
        });
  }

  /// Get outgoing friend requests stream
  Stream<List<Map<String, dynamic>>> getOutgoingFriendRequestsStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> requestsWithUserData = [];

          for (var doc in snapshot.docs) {
            try {
              final request = FriendRequestModel.fromMap(
                doc.data(),
                docId: doc.id,
              );

              // Get receiver's user data
              final receiverDoc = await _firestore
                  .collection('users')
                  .doc(request.receiverId)
                  .get();

              if (receiverDoc.exists) {
                final receiverData = receiverDoc.data()!;
                receiverData['id'] = receiverDoc.id;

                final receiverUser = UserModel.fromMap(receiverData);

                requestsWithUserData.add({
                  'id': request.id,
                  'toUser': receiverUser.toMap(),
                });
              }
            } catch (e) {
              // Silently skip invalid requests
            }
          }

          return requestsWithUserData;
        });
  }

  /// Accept friend request
  Future<void> acceptFriendRequest(String requestId, String senderId) async {
    if (currentUserId == null) return;

    try {
      await _firestore.runTransaction((transaction) async {
        // Update request status
        final requestRef = _firestore
            .collection('friendRequests')
            .doc(requestId);
        transaction.update(requestRef, {
          'status': 'accepted',
          'respondedAt': FieldValue.serverTimestamp(),
        });

        // Add to both users' friend lists
        final currentUserRef = _firestore
            .collection('users')
            .doc(currentUserId);
        final senderUserRef = _firestore.collection('users').doc(senderId);

        transaction.update(currentUserRef, {
          'friends': FieldValue.arrayUnion([senderId]),
        });

        transaction.update(senderUserRef, {
          'friends': FieldValue.arrayUnion([currentUserId]),
        });
      });
    } catch (e) {
      print('Error accepting friend request: $e');
      rethrow;
    }
  }

  /// Reject friend request
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error rejecting friend request: $e');
      rethrow;
    }
  }

  /// Decline friend request (alias for rejectFriendRequest)
  Future<void> declineFriendRequest(String requestId) async {
    return rejectFriendRequest(requestId);
  }

  /// Cancel outgoing friend request
  Future<void> cancelFriendRequest(String requestId) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).delete();
    } catch (e) {
      print('Error canceling friend request: $e');
      rethrow;
    }
  }

  /// Get count of pending incoming requests
  Stream<int> getPendingRequestsCountStream() {
    if (currentUserId == null) return Stream.value(0);

    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ============================================================================
  // FRIENDS MANAGEMENT METHODS
  // ============================================================================

  /// Remove friend (complete unfriend - removes from both sides)
  Future<void> removeFriend(String friendId) async {
    if (currentUserId == null) return;

    try {
      await _firestore.runTransaction((transaction) async {
        final currentUserRef = _firestore
            .collection('users')
            .doc(currentUserId);
        final friendUserRef = _firestore.collection('users').doc(friendId);

        transaction.update(currentUserRef, {
          'friends': FieldValue.arrayRemove([friendId]),
        });

        transaction.update(friendUserRef, {
          'friends': FieldValue.arrayRemove([currentUserId]),
        });
      });
    } catch (e) {
      print('Error removing friend: $e');
      rethrow;
    }
  }

  /// Unfriend user (complete removal - removes all chat data, settings, themes)
  Future<void> unfriendUser(String friendId) async {
    if (currentUserId == null) return;

    try {
      // Get chat ID for this friendship
      final chatId = await _getChatId(currentUserId!, friendId);
      
      await _firestore.runTransaction((transaction) async {
        // Remove from friends list on both sides
        final currentUserRef = _firestore.collection('users').doc(currentUserId);
        final friendUserRef = _firestore.collection('users').doc(friendId);

        transaction.update(currentUserRef, {
          'friends': FieldValue.arrayRemove([friendId]),
        });

        transaction.update(friendUserRef, {
          'friends': FieldValue.arrayRemove([currentUserId]),
        });

        // Delete all chat-related data for current user
        if (chatId != null) {
          // Delete chat settings
          final settingsId = '${chatId}_$currentUserId';
          transaction.delete(_firestore.collection('chatSettings').doc(settingsId));
          
          // Delete chat stats
          transaction.delete(_firestore.collection('chatStats').doc(settingsId));
          
          // Delete chat document (only if both users unfriend)
          // For now, we'll keep the chat document but mark it as inactive
          transaction.update(_firestore.collection('chats').doc(chatId), {
            'isActive': false,
            'unfriendedBy': currentUserId,
            'unfriendedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Error unfriending user: $e');
      rethrow;
    }
  }

  /// Delete chat (user-side only - other user can still see chat)
  Future<void> deleteChatForUser(String friendId) async {
    if (currentUserId == null) return;

    try {
      final chatId = await _getChatId(currentUserId!, friendId);
      
      if (chatId != null) {
        await _firestore.runTransaction((transaction) async {
          // Delete chat settings for current user only
          final settingsId = '${chatId}_$currentUserId';
          transaction.delete(_firestore.collection('chatSettings').doc(settingsId));
          
          // Delete chat stats for current user only
          transaction.delete(_firestore.collection('chatStats').doc(settingsId));
          
          // Mark chat as deleted for current user
          transaction.update(_firestore.collection('chats').doc(chatId), {
            'deletedBy': FieldValue.arrayUnion([currentUserId]),
            'deletedAt': FieldValue.serverTimestamp(),
          });
        });
      }
    } catch (e) {
      print('Error deleting chat: $e');
      rethrow;
    }
  }

  /// Block user (comprehensive blocking with mutual restrictions)
  Future<void> blockUser(String userId) async {
    if (currentUserId == null) return;

    try {
      // Get chat ID for this friendship (if it exists)
      final chatId = await _getChatId(currentUserId!, userId);
      
      await _firestore.runTransaction((transaction) async {
        final currentUserRef = _firestore.collection('users').doc(currentUserId);
        final blockedUserRef = _firestore.collection('users').doc(userId);
        
        // Add to blocked users list and remove from friends
        transaction.update(currentUserRef, {
          'blockedUsers': FieldValue.arrayUnion([userId]),
          'friends': FieldValue.arrayRemove([userId]),
        });

        // Remove current user from the blocked user's friends list
        transaction.update(blockedUserRef, {
          'friends': FieldValue.arrayRemove([currentUserId]),
        });

        // Delete all chat-related data for BOTH users
        if (chatId != null) {
          // Delete chat settings for both users
          final currentUserSettingsId = '${chatId}_$currentUserId';
          final blockedUserSettingsId = '${chatId}_$userId';
          
          transaction.delete(_firestore.collection('chatSettings').doc(currentUserSettingsId));
          transaction.delete(_firestore.collection('chatSettings').doc(blockedUserSettingsId));
          
          // Delete chat stats for both users
          transaction.delete(_firestore.collection('chatStats').doc(currentUserSettingsId));
          transaction.delete(_firestore.collection('chatStats').doc(blockedUserSettingsId));
          
          // Mark chat as completely blocked and inactive
          transaction.update(_firestore.collection('chats').doc(chatId), {
            'isActive': false,
            'blockedBy': currentUserId,
            'blockedAt': FieldValue.serverTimestamp(),
            'isBlocked': true,
            'blockedUsers': FieldValue.arrayUnion([currentUserId, userId]),
          });
        }

        // Delete any pending friend requests between these users
        await _deleteFriendRequestsBetweenUsers(transaction, currentUserId!, userId);
      });
    } catch (e) {
      print('Error blocking user: $e');
      rethrow;
    }
  }

  /// Unblock user (does NOT restore friendship - they need to add each other again)
  Future<void> unblockUser(String userId) async {
    if (currentUserId == null) return;

    try {
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      
      await _firestore.runTransaction((transaction) async {
        // Only remove from blocked users list - do NOT add back to friends
        transaction.update(currentUserRef, {
          'blockedUsers': FieldValue.arrayRemove([userId]),
        });
      });
    } catch (e) {
      print('Error unblocking user: $e');
      rethrow;
    }
  }

  /// Helper method to delete friend requests between two users
  Future<void> _deleteFriendRequestsBetweenUsers(Transaction transaction, String userId1, String userId2) async {
    try {
      // Delete requests from userId1 to userId2
      final requestsFrom1To2 = await _firestore
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: userId1)
          .where('toUserId', isEqualTo: userId2)
          .get();

      for (final doc in requestsFrom1To2.docs) {
        transaction.delete(doc.reference);
      }

      // Delete requests from userId2 to userId1
      final requestsFrom2To1 = await _firestore
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: userId2)
          .where('toUserId', isEqualTo: userId1)
          .get();

      for (final doc in requestsFrom2To1.docs) {
        transaction.delete(doc.reference);
      }
    } catch (e) {
      print('Error deleting friend requests between users: $e');
    }
  }

  /// Check if user is blocked
  Future<bool> isUserBlocked(String userId) async {
    if (currentUserId == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (userDoc.exists) {
        final blockedUsers = List<String>.from(userDoc.data()?['blockedUsers'] ?? []);
        return blockedUsers.contains(userId);
      }
      return false;
    } catch (e) {
      print('Error checking if user is blocked: $e');
      return false;
    }
  }

  /// Check if there's mutual blocking between two users
  Future<bool> isMutualBlocking(String userId) async {
    if (currentUserId == null) return false;

    try {
      // Check if current user blocked the other user
      final currentUserBlocked = await isUserBlocked(userId);
      
      // Check if the other user blocked current user
      final otherUserDoc = await _firestore.collection('users').doc(userId).get();
      bool otherUserBlocked = false;
      if (otherUserDoc.exists) {
        final otherBlockedUsers = List<String>.from(otherUserDoc.data()?['blockedUsers'] ?? []);
        otherUserBlocked = otherBlockedUsers.contains(currentUserId);
      }

      return currentUserBlocked || otherUserBlocked;
    } catch (e) {
      print('Error checking mutual blocking: $e');
      return false;
    }
  }

  /// Check if user can interact with another user (not blocked either way)
  Future<bool> canInteractWithUser(String userId) async {
    if (currentUserId == null) return false;
    return !(await isMutualBlocking(userId));
  }

  /// Get list of blocked users
  Future<List<UserModel>> getBlockedUsers() async {
    if (currentUserId == null) return [];

    try {
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return [];

      final blockedUserIds = List<String>.from(userDoc.data()?['blockedUsers'] ?? []);
      if (blockedUserIds.isEmpty) return [];

      final blockedUsers = <UserModel>[];
      
      // Get user data for each blocked user
      for (final userId in blockedUserIds) {
        try {
          final blockedUserDoc = await _firestore.collection('users').doc(userId).get();
          if (blockedUserDoc.exists) {
            blockedUsers.add(UserModel.fromFirestore(blockedUserDoc));
          }
        } catch (e) {
          print('Error getting blocked user $userId: $e');
        }
      }
      
      return blockedUsers;
    } catch (e) {
      print('Error getting blocked users: $e');
      return [];
    }
  }

  /// Get chat ID between two users
  Future<String?> _getChatId(String userId1, String userId2) async {
    try {
      // Try both combinations of user IDs
      final chatId1 = '${userId1}_$userId2';
      final chatId2 = '${userId2}_$userId1';
      
      final chat1Doc = await _firestore.collection('chats').doc(chatId1).get();
      if (chat1Doc.exists) return chatId1;
      
      final chat2Doc = await _firestore.collection('chats').doc(chatId2).get();
      if (chat2Doc.exists) return chatId2;
      
      return null;
    } catch (e) {
      print('Error getting chat ID: $e');
      return null;
    }
  }

  /// Get recommended users (excluding friends, blocked users, and current user)
  Future<List<UserModel>> getRecommendedUsers() async {
    if (currentUserId == null) return [];

    try {
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!currentUserDoc.exists) return [];

      final currentUserData = currentUserDoc.data()!;
      final friends = List<String>.from(currentUserData['friends'] ?? []);
      final blockedUsers = List<String>.from(currentUserData['blockedUsers'] ?? []);
      
      // Get all users except current user, friends, and blocked users
      final querySnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: currentUserId)
          .limit(20)
          .get();

      final recommendations = <UserModel>[];
      
      for (final doc in querySnapshot.docs) {
        final userId = doc.id;
        
        // Skip if user is already a friend or blocked
        if (friends.contains(userId) || blockedUsers.contains(userId)) {
          continue;
        }
        
        // Check if there's already a pending friend request
        final hasPendingRequest = await _hasPendingFriendRequest(userId);
        if (hasPendingRequest) continue;
        
        recommendations.add(UserModel.fromFirestore(doc));
      }
      
      return recommendations;
    } catch (e) {
      print('Error getting recommended users: $e');
      return [];
    }
  }

  /// Get mutual friend suggestions (users who have mutual friends with current user)
  Future<List<UserModel>> getMutualFriendSuggestions() async {
    if (currentUserId == null) return [];

    try {
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!currentUserDoc.exists) return [];

      final currentUserData = currentUserDoc.data()!;
      final friends = List<String>.from(currentUserData['friends'] ?? []);
      final blockedUsers = List<String>.from(currentUserData['blockedUsers'] ?? []);
      
      if (friends.isEmpty) {
        // If user has no friends, return general recommendations
        return getRecommendedUsers();
      }

      // Get friends of friends (potential mutual connections)
      final Set<String> potentialMutualFriends = {};
      
      for (final friendId in friends.take(10)) { // Limit to avoid too many queries
        try {
          final friendDoc = await _firestore.collection('users').doc(friendId).get();
          if (friendDoc.exists) {
            final friendData = friendDoc.data()!;
            final friendFriends = List<String>.from(friendData['friends'] ?? []);
            
            // Add friends of this friend to potential mutual friends
            for (final friendOfFriend in friendFriends) {
              if (friendOfFriend != currentUserId && 
                  !friends.contains(friendOfFriend) && 
                  !blockedUsers.contains(friendOfFriend)) {
                potentialMutualFriends.add(friendOfFriend);
              }
            }
          }
        } catch (e) {
          print('Error getting friend data for $friendId: $e');
        }
      }

      // Get user data for potential mutual friends
      final suggestions = <UserModel>[];
      
      for (final userId in potentialMutualFriends.take(20)) {
        try {
          // Check if there's already a pending friend request
          final hasPendingRequest = await _hasPendingFriendRequest(userId);
          if (hasPendingRequest) continue;
          
          // Check if there's mutual blocking
          final canInteract = await canInteractWithUser(userId);
          if (!canInteract) continue;
          
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            suggestions.add(UserModel.fromFirestore(userDoc));
          }
        } catch (e) {
          print('Error getting user data for $userId: $e');
        }
      }
      
      return suggestions;
    } catch (e) {
      print('Error getting mutual friend suggestions: $e');
      return [];
    }
  }

  /// Search users by name or username (excluding blocked users)
  Future<List<UserModel>> searchUsers(String query) async {
    if (currentUserId == null || query.isEmpty) return [];

    try {
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!currentUserDoc.exists) return [];

      final currentUserData = currentUserDoc.data()!;
      final blockedUsers = List<String>.from(currentUserData['blockedUsers'] ?? []);
      
      final searchQuery = query.toLowerCase();
      
      // Search by display name
      final nameQuery = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: searchQuery)
          .where('displayName', isLessThan: searchQuery + '\uf8ff')
          .limit(10)
          .get();

      // Search by username
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: searchQuery)
          .where('username', isLessThan: searchQuery + '\uf8ff')
          .limit(10)
          .get();

      final results = <String, UserModel>{};
      
      // Process name results
      for (final doc in nameQuery.docs) {
        final userId = doc.id;
        if (userId != currentUserId && !blockedUsers.contains(userId)) {
          // Check if there's mutual blocking
          final canInteract = await canInteractWithUser(userId);
          if (canInteract) {
            results[userId] = UserModel.fromFirestore(doc);
          }
        }
      }
      
      // Process username results
      for (final doc in usernameQuery.docs) {
        final userId = doc.id;
        if (userId != currentUserId && !blockedUsers.contains(userId)) {
          // Check if there's mutual blocking
          final canInteract = await canInteractWithUser(userId);
          if (canInteract) {
            results[userId] = UserModel.fromFirestore(doc);
          }
        }
      }
      
      return results.values.toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Check if there's a pending friend request between current user and target user
  Future<bool> _hasPendingFriendRequest(String targetUserId) async {
    if (currentUserId == null) return false;

    try {
      // Check outgoing requests
      final outgoingQuery = await _firestore
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: currentUserId)
          .where('toUserId', isEqualTo: targetUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (outgoingQuery.docs.isNotEmpty) return true;

      // Check incoming requests
      final incomingQuery = await _firestore
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: targetUserId)
          .where('toUserId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'pending')
          .get();

      return incomingQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error checking pending friend request: $e');
      return false;
    }
  }

  /// Get friends stream with privacy-aware online status (excluding blocked users)
  Stream<List<UserModel>> getFriendsStream(List<String> friendIds) {
    if (friendIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendIds)
        .snapshots()
        .asyncMap(
          (snapshot) async {
            final friends = <UserModel>[];
            
            for (final doc in snapshot.docs) {
            final userData = UserModel.fromMap({...doc.data(), 'id': doc.id});
              
              // Check if this user is blocked
              final isBlocked = await isUserBlocked(userData.id);
              if (isBlocked) continue; // Skip blocked users
              
            // If user has disabled showing online status, show them as offline
            if (!userData.showOnlineStatus) {
                friends.add(userData.copyWith(isOnline: false));
              } else {
                friends.add(userData);
              }
            }
            
            return friends;
          },
        );
  }

  /// Get user statistics
  Future<Map<String, int>> getUserStatistics(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return {};

      final userData = userDoc.data()!;

      return {
        'friendsCount': (userData['friends'] as List?)?.length ?? 0,
        'pendingRequestsCount': await _getPendingRequestsCount(userId),
        'sentRequestsCount': await _getSentRequestsCount(userId),
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      return {};
    }
  }

  Future<int> _getPendingRequestsCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('friendRequests')
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getSentRequestsCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // ============================================================================
  // CHAT AND MESSAGING METHODS
  // ============================================================================

  /// Create or get private chat between two users
  Future<String> createOrGetPrivateChat(String otherUserId) async {
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      // Create consistent chat ID
      final participants = [currentUserId!, otherUserId]..sort();
      final chatId = participants.join('_');

      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();

      if (!chatDoc.exists) {
        await chatRef.set({
          'id': chatId,
          'participants': participants,
          'chatType': 'private',
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': null,
          'lastMessageTime': null,
          'unreadCount': {currentUserId!: 0, otherUserId: 0},
        });
      }

      return chatId;
    } catch (e) {
      print('Error creating or getting private chat: $e');
      rethrow;
    }
  }

  // ============================================================================
  // NOTES AND MESSAGING METHODS
  // ============================================================================

  /// Send note to user (special message type)
  Future<void> sendNoteToUser(String recipientId, String noteContent) async {
    try {
      if (currentUserId == null) throw Exception('No authenticated user');

      if (noteContent.trim().isEmpty) {
        throw Exception('Note content cannot be empty');
      }

      if (noteContent.length > 500) {
        throw Exception('Note content must be less than 500 characters');
      }

      // Create a special note document
      await _firestore.collection('notes').add({
        'senderId': currentUserId,
        'recipientId': recipientId,
        'content': noteContent.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'note',
      });

      // Add to recipient's notifications
      await _firestore.collection('notifications').add({
        'userId': recipientId,
        'type': 'note_received',
        'title': 'New Note',
        'body': 'You received a note from someone!',
        'data': {'senderId': currentUserId, 'noteContent': noteContent.trim()},
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error sending note: $e');
      rethrow;
    }
  }

  /// Get received notes for current user
  Stream<List<Map<String, dynamic>>> getReceivedNotesStream() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('notes')
        .where('recipientId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// Mark note as read
  Future<void> markNoteAsRead(String noteId) async {
    try {
      await _firestore.collection('notes').doc(noteId).update({'isRead': true});
    } catch (e) {
      print('Error marking note as read: $e');
      rethrow;
    }
  }

  /// Delete note
  Future<void> deleteNote(String noteId) async {
    try {
      await _firestore.collection('notes').doc(noteId).delete();
    } catch (e) {
      print('Error deleting note: $e');
      rethrow;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Helper method to calculate age
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

}
