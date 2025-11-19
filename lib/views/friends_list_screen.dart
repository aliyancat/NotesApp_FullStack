// views/friends_list_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:tutortyper_app/services/user_service.dart';
import 'package:tutortyper_app/views/enhanced_chat_screen.dart';
import 'package:tutortyper_app/views/enhanced_friend_requests_screen.dart';
import 'package:tutortyper_app/views/add_friends_screen.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  final Set<String> _pinnedFriends = {}; // Store pinned friend IDs

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Friends',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 24),
        ),
        backgroundColor: const Color(0xFF68EAFF),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF68EAFF),
                Color(0xFF4FD1C7),
              ],
            ),
          ),
        ),
        actions: [
          // Friend Requests Button with Badge
          StreamBuilder<int>(
            stream: _userService.getPendingRequestsCountStream(),
            builder: (context, snapshot) {
              final pendingCount = snapshot.data ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mail_outline),
                    onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EnhancedFriendRequestsScreen(),
              ),
            );
                    },
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddFriendsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF68EAFF),
                  Color(0xFF4FD1C7),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                hintText: 'Search friends...',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 16,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF64748B),
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF68EAFF),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {}); // Trigger rebuild for search
              },
            ),
          ),

          // Friends List
          Expanded(
            child: StreamBuilder<UserModel?>(
              stream: _userService.getCurrentUserStream(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!userSnapshot.hasData ||
                    userSnapshot.data?.friends.isEmpty == true) {
                  return _buildEmptyState();
                }

                final currentUser = userSnapshot.data!;
                return StreamBuilder<List<UserModel>>(
                  stream: _userService.getFriendsStream(currentUser.friends),
                  builder: (context, friendsSnapshot) {
                    if (friendsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!friendsSnapshot.hasData ||
                        friendsSnapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    List<UserModel> friends = friendsSnapshot.data!;

                    // Filter friends based on search
                    if (_searchController.text.isNotEmpty) {
                      friends = friends
                          .where(
                            (friend) =>
                                friend.displayName.toLowerCase().contains(
                                  _searchController.text.toLowerCase(),
                                ) ||
                                friend.username.toLowerCase().contains(
                                  _searchController.text.toLowerCase(),
                                ) ||
                                friend.email.toLowerCase().contains(
                                  _searchController.text.toLowerCase(),
                                ),
                          )
                          .toList();
                    }

                    // Sort friends: pinned first, then by online status, then alphabetically
                    friends.sort((a, b) {
                      if (_pinnedFriends.contains(a.id) &&
                          !_pinnedFriends.contains(b.id)) {
                        return -1;
                      } else if (!_pinnedFriends.contains(a.id) &&
                          _pinnedFriends.contains(b.id)) {
                        return 1;
                      } else if (a.isOnline && !b.isOnline) {
                        return -1;
                      } else if (!a.isOnline && b.isOnline) {
                        return 1;
                      } else {
                        return a.displayName.compareTo(b.displayName);
                      }
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        return _buildEnhancedFriendCard(friends[index]);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No friends yet',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send friend requests to start connecting!',
            style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showSendFriendRequestDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Send Friend Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 104, 234, 243),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFriendCard(UserModel friend) {
    final bool isPinned = _pinnedFriends.contains(friend.id);
    final bool isVerified = friend.isVerified;
    final String bio = friend.bio ?? "";
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.06),
            offset: const Offset(0, 4),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
        border: isPinned
            ? Border.all(
                color: const Color(0xFF68EAFF),
                width: 2,
              )
            : null,
      ),
      child: InkWell(
        onTap: () => _startChat(friend),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Profile Picture with Online Status
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: friend.isOnline
                            ? const Color(0xFF10B981)
                            : const Color(0xFFE2E8F0),
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: friend.photoUrl != null
                          ? CachedNetworkImageProvider(friend.photoUrl!)
                          : null,
                      backgroundColor: const Color(0xFF68EAFF),
                      child: friend.photoUrl == null
                          ? Text(
                              friend.displayName.isNotEmpty
                                  ? friend.displayName[0].toUpperCase()
                                  : 'U',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (friend.isOnline)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            friend.displayName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: const Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF3B82F6),
                            size: 18,
                          ),
                        ],
                        if (isPinned) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.push_pin_rounded,
                            color: Color(0xFF68EAFF),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${friend.username}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: friend.isOnline
                                ? const Color(0xFF10B981)
                                : const Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          friend.isOnline
                              ? 'Online'
                              : 'Last seen ${_formatLastSeen(friend.lastSeen)}',
                          style: GoogleFonts.inter(
                            color: friend.isOnline
                                ? const Color(0xFF10B981)
                                : const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        bio,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Action Buttons
              IconButton(
                onPressed: () => _togglePin(friend.id),
                icon: Icon(
                  isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  color: isPinned
                      ? const Color(0xFF68EAFF)
                      : const Color(0xFF94A3B8),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _togglePin(String friendId) {
    setState(() {
      if (_pinnedFriends.contains(friendId)) {
        _pinnedFriends.remove(friendId);
      } else {
        _pinnedFriends.add(friendId);
      }
    });
  }

  void _showFriendProfileDialog(UserModel friend) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 40,
                backgroundImage: friend.photoUrl != null
                    ? CachedNetworkImageProvider(friend.photoUrl!)
                    : null,
                backgroundColor: const Color.fromARGB(255, 104, 234, 243),
                child: friend.photoUrl == null
                    ? Text(
                        friend.displayName.isNotEmpty
                            ? friend.displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      )
                    : null,
              ),

              const SizedBox(height: 16),

              // Name and verification
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    friend.displayName,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  if (friend.isVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, color: Colors.blue, size: 24),
                  ],
                ],
              ),

              Text(
                '@${friend.username}',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),

              const SizedBox(height: 16),

              // Bio - only show if not empty
              if (friend.bio != null && friend.bio!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    friend.bio!,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
              ] else
                const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startChat(friend);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          104,
                          234,
                          243,
                        ),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Chat'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showSendNoteDialog(friend);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color.fromARGB(
                          255,
                          104,
                          234,
                          243,
                        ),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 104, 234, 243),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Send Note'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSendNoteDialog(UserModel friend) {
    final noteController = TextEditingController();

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      width: MediaQuery.of(context).size.width * 0.9,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.note_add,
              size: 50,
              color: Color.fromARGB(255, 104, 234, 243),
            ),
            const SizedBox(height: 16),
            Text(
              'Send Note to ${friend.displayName}',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a quick note that will appear in their notifications',
              style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: 'Your Note',
                hintText: 'Type your note here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.message),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (noteController.text.trim().isNotEmpty) {
                        Navigator.of(context).pop();
                        _sendNote(friend, noteController.text.trim());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 104, 234, 243),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Send Note'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).show();
  }

  void _sendNote(UserModel friend, String note) {
    // TODO: Implement note sending functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Note sent to ${friend.displayName}'),
        backgroundColor: const Color.fromARGB(255, 104, 234, 243),
      ),
    );
  }

  void _showFriendOptions(UserModel friend) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Friend Info Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: friend.photoUrl != null
                        ? CachedNetworkImageProvider(friend.photoUrl!)
                        : null,
                    backgroundColor: const Color.fromARGB(255, 104, 234, 243),
                    child: friend.photoUrl == null
                        ? Text(
                            friend.displayName.isNotEmpty
                                ? friend.displayName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.displayName,
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '@${friend.username}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),

              // Options
              _buildOptionTile(
                icon: Icons.chat,
                title: 'Start Chat',
                onTap: () {
                  Navigator.pop(context);
                  _startChat(friend);
                },
              ),

              _buildOptionTile(
                icon: Icons.note_add,
                title: 'Send Note',
                onTap: () {
                  Navigator.pop(context);
                  _showSendNoteDialog(friend);
                },
              ),

              _buildOptionTile(
                icon: Icons.notifications_off,
                title: 'Mute Notifications',
                onTap: () {
                  Navigator.pop(context);
                  _showMuteOptions(friend);
                },
              ),

              _buildOptionTile(
                icon: Icons.delete_outline,
                title: 'Delete Chat',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteChat(friend);
                },
              ),

              _buildOptionTile(
                icon: Icons.person_remove,
                title: 'Remove Friend',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _confirmRemoveFriend(friend);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final optionColor = color ?? Colors.grey[700];

    return ListTile(
      leading: Icon(icon, color: optionColor),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          color: optionColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  void _showMuteOptions(UserModel friend) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      width: MediaQuery.of(context).size.width * 0.8,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.notifications_off, size: 50, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Mute ${friend.displayName}',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              ('15 minutes', '15m'),
              ('1 hour', '1h'),
              ('8 hours', '8h'),
              ('24 hours', '24h'),
              ('Until I turn it back on', 'forever'),
            ].map(
              (option) => ListTile(
                title: Text(option.$1),
                onTap: () {
                  Navigator.of(context).pop();
                  _muteChat(friend, option.$2);
                },
              ),
            ),
          ],
        ),
      ),
    ).show();
  }

  void _confirmDeleteChat(UserModel friend) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Delete Chat',
      desc:
          'Are you sure you want to delete your chat history with ${friend.displayName}? This action cannot be undone.',
      btnCancelOnPress: () {},
      btnOkOnPress: () => _deleteChat(friend),
      btnOkColor: Colors.orange,
      btnOkText: 'Delete',
      btnCancelText: 'Cancel',
    ).show();
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }

  void _startChat(UserModel friend) async {
    try {
      final chatId = await _userService.createOrGetPrivateChat(friend.id);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                EnhancedChatScreen(chatId: chatId, otherUser: friend),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to start chat: $e');
    }
  }

  void _muteChat(UserModel friend, String duration) {
    // TODO: Implement mute functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Muted ${friend.displayName} for $duration'),
        backgroundColor: const Color.fromARGB(255, 104, 234, 243),
      ),
    );
  }

  void _deleteChat(UserModel friend) async {
    try {
      final chatId = await _userService.createOrGetPrivateChat(friend.id);
      // TODO: Implement delete chat functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat history deleted'),
          backgroundColor: Color.fromARGB(255, 104, 234, 243),
        ),
      );
    } catch (e) {
      _showErrorDialog('Failed to delete chat: $e');
    }
  }

  void _showSendFriendRequestDialog() {
    final usernameController = TextEditingController();

    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      width: MediaQuery.of(context).size.width * 0.9,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.person_add,
              size: 50,
              color: Color.fromARGB(255, 104, 234, 243),
            ),
            const SizedBox(height: 16),
            Text(
              'Send Friend Request',
              style: GoogleFonts.nunito(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The user will receive a request and can choose to accept or decline',
              style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Friend\'s Username',
                hintText: 'Enter username (without @)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.alternate_email),
              ),
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
              enableSuggestions: false,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the username without the @ symbol',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _sendFriendRequest(usernameController.text.trim());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 104, 234, 243),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Send Request'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).show();
  }

  void _sendFriendRequest(String username) async {
    if (username.isEmpty) {
      _showErrorDialog('Please enter a username');
      return;
    }

    // Remove @ if user included it
    if (username.startsWith('@')) {
      username = username.substring(1);
    }

    try {
      final success = await _userService.sendFriendRequest(username);
      if (success) {
        _showSuccessDialog('Friend request sent to @$username!');
      } else {
        _showErrorDialog('User @$username not found');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceFirst('Exception:', '').trim();
      }
      _showErrorDialog(errorMessage);
    }
  }

  void _confirmRemoveFriend(UserModel friend) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Remove Friend',
      desc:
          'Are you sure you want to remove ${friend.displayName} (@${friend.username}) from your friends?',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        _removeFriend(friend);
      },
      btnOkColor: Colors.red,
      btnOkText: 'Remove',
      btnCancelText: 'Cancel',
    ).show();
  }

  void _removeFriend(UserModel friend) async {
    try {
      await _userService.removeFriend(friend.id);
      _showSuccessDialog('Friend @${friend.username} removed successfully');
    } catch (e) {
      _showErrorDialog('Failed to remove friend: $e');
    }
  }

  void _showSuccessDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: 'Success',
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Error',
      desc: message,
      btnOkOnPress: () {},
    ).show();
  }
}

