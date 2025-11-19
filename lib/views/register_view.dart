import 'dart:async';
import 'package:tutortyper_app/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:tutortyper_app/firebase_options.dart';
import 'package:tutortyper_app/views/login_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _confirmPassword;
  late final TextEditingController _username;
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool _isUsernameValid = false;
  String? _usernameErrorMessage;

  // Add debounce timer
  Timer? _debounceTimer;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _confirmPassword = TextEditingController();
    _username = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _username.dispose();
    _debounceTimer?.cancel(); // Cancel timer on dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Lottie Background
          SizedBox.expand(
            child: Lottie.asset(
              'assets/animations/login_background.json',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Center(child: Text('Background not available')),
                );
              },
            ),
          ),
          FutureBuilder(
            future: Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            ),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.done:
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Text(
                            'Register',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              fontSize: 36,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Username Field with debounced checking
                          TextField(
                            controller: _username,
                            decoration: InputDecoration(
                              hintText: 'Choose a unique username',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(200),
                                borderSide: BorderSide(
                                  color: _getFieldBorderColor(),
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(200),
                                borderSide: BorderSide(
                                  color: _getFieldBorderColor(),
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(200),
                                borderSide: BorderSide(
                                  color: _isUsernameValid
                                      ? Colors.green
                                      : const Color.fromARGB(
                                          255,
                                          104,
                                          234,
                                          243,
                                        ),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              prefixIcon: const Icon(
                                Icons.alternate_email,
                                color: Colors.grey,
                              ),
                              suffixIcon: _getSuffixIcon(),
                            ),
                            enableSuggestions: false,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            style: const TextStyle(color: Colors.black),
                            enabled: !_isLoading,
                            onChanged:
                                _onUsernameChanged, // Changed method name
                          ),
                          if (_usernameErrorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 16),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _usernameErrorMessage!,
                                  style: TextStyle(
                                    color: Colors.red[300],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          if (_isUsernameValid && _username.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 16),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Username @${_username.text} is available!',
                                  style: TextStyle(
                                    color: Colors.green[300],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Email Field
                          TextField(
                            controller: _email,
                            decoration: InputDecoration(
                              hintText: 'Enter Email',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(200),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              prefixIcon: const Icon(
                                Icons.email,
                                color: Colors.grey,
                              ),
                            ),
                            enableSuggestions: false,
                            autocorrect: false,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.black),
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          TextField(
                            controller: _password,
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(200),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Colors.grey,
                              ),
                            ),
                            obscureText: true,
                            enableSuggestions: false,
                            autocorrect: false,
                            style: const TextStyle(color: Colors.black),
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password Field
                          TextField(
                            controller: _confirmPassword,
                            decoration: InputDecoration(
                              hintText: 'Confirm Password',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(200),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.9),
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Colors.grey,
                              ),
                            ),
                            obscureText: true,
                            enableSuggestions: false,
                            autocorrect: false,
                            style: const TextStyle(color: Colors.black),
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 30),

                          ElevatedButton(
                            onPressed:
                                (_isLoading ||
                                    !_isUsernameValid ||
                                    _username.text.isEmpty)
                                ? null
                                : _registerUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  (_isLoading ||
                                      !_isUsernameValid ||
                                      _username.text.isEmpty)
                                  ? Colors.grey
                                  : const Color.fromARGB(255, 80, 195, 248),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(200),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Register Now!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginView(),
                                      ),
                                    );
                                  },
                            child: const Text(
                              'Already have an account? Login here',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                default:
                  return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ],
      ),
    );
  }

  Color _getFieldBorderColor() {
    if (_username.text.isEmpty) return Colors.grey;
    if (_isCheckingUsername) return const Color.fromARGB(255, 104, 234, 243);
    if (_isUsernameValid) return Colors.green;
    return Colors.red;
  }

  Widget? _getSuffixIcon() {
    if (_username.text.isEmpty) return null;

    if (_isCheckingUsername) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color.fromARGB(255, 104, 234, 243),
          ),
        ),
      );
    }

    return Icon(
      _isUsernameValid ? Icons.check_circle : Icons.error,
      color: _isUsernameValid ? Colors.green : Colors.red,
    );
  }

  // NEW: Debounced username input handler
  void _onUsernameChanged(String username) {
    // Cancel previous timer if it exists
    _debounceTimer?.cancel();

    // Only clear states if username becomes empty
    if (username.isEmpty) {
      if (mounted) {
        setState(() {
          _usernameErrorMessage = null;
          _isUsernameValid = false;
          _isCheckingUsername = false;
        });
      }
      return;
    }

    // Start a new timer - check username after user stops typing
    _debounceTimer = Timer(const Duration(milliseconds: 1200), () {
      // Double check the username hasn't changed and widget is still mounted
      if (mounted && _username.text.trim() == username.trim()) {
        _checkUsernameDebounced(username.trim());
      }
    });
  }

  // Separate method for debounced checking to avoid conflicts
  void _checkUsernameDebounced(String username) async {
    if (!mounted) return;

    // Check minimum length first
    if (username.length < 3) {
      if (mounted) {
        setState(() {
          _usernameErrorMessage = 'Username must be at least 3 characters';
          _isCheckingUsername = false;
          _isUsernameValid = false;
        });
      }
      return;
    }

    // Validate username format
    if (!_isValidUsername(username)) {
      if (mounted) {
        setState(() {
          _usernameErrorMessage =
              'Username can only contain letters, numbers, and underscores';
          _isCheckingUsername = false;
          _isUsernameValid = false;
        });
      }
      return;
    }

    // Start checking availability
    if (mounted) {
      setState(() {
        _isCheckingUsername = true;
        _usernameErrorMessage = null;
        _isUsernameValid = false;
      });
    }

    try {
      final userService = UserService();
      final isAvailable = await userService.isUsernameAvailable(username);

      if (mounted) {
        setState(() {
          _isUsernameValid = isAvailable;
          _isCheckingUsername = false;
          if (!isAvailable) {
            _usernameErrorMessage = 'Username @$username is already taken';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUsernameValid = false;
          _isCheckingUsername = false;
          _usernameErrorMessage = 'Error checking username availability';
        });
      }
    }
  }

  // Enhanced username checking - now only called during registration
  void _checkUsername(String username) async {
    // This method is now only used during final registration validation
    final userService = UserService();
    final isAvailable = await userService.isUsernameAvailable(username);

    if (!isAvailable) {
      throw Exception('Username is no longer available');
    }
  }

  bool _isValidUsername(String username) {
    // Username should be 3-20 characters, alphanumeric and underscores only
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }

  Future<void> _registerUser() async {
    final email = _email.text.trim();
    final password = _password.text.trim();
    final confirmPassword = _confirmPassword.text.trim();
    final username = _username.text.trim();

    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      _showDialog(
        DialogType.warning,
        'Missing Fields',
        'Please fill in all required fields.',
      );
      return;
    }

    if (!_isUsernameValid) {
      _showDialog(
        DialogType.warning,
        'Invalid Username',
        'Please choose a valid and available username.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showDialog(
        DialogType.warning,
        'Password Mismatch',
        'The passwords you entered do not match.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG: Starting registration process...');
      print('DEBUG: Email: $email, Username: $username');

      // Double-check username availability before proceeding
      final userService = UserService();
      final isUsernameStillAvailable = await userService.isUsernameAvailable(
        username,
      );

      if (!isUsernameStillAvailable) {
        _showDialog(
          DialogType.error,
          'Username Taken',
          'This username was recently taken. Please choose another one.',
        );
        return;
      }

      // Step 1: Create Firebase Auth account
      print('DEBUG: Creating Firebase Auth account...');
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user == null) {
        throw Exception('Failed to create user account');
      }

      print(
        'DEBUG: ✅ Firebase Auth account created with UID: ${userCredential.user!.uid}',
      );

      // Step 2: Create user profile in Firestore with username
      print('DEBUG: Creating Firestore user profile...');

      await userService.createUserProfile(
        userId: userCredential.user!.uid,
        email: email.toLowerCase(),
        displayName: username,
        username: username.toLowerCase(),
        photoUrl: userCredential.user!.photoURL,
      );

      print('DEBUG: ✅ Firestore user profile created');

      // Step 3: Verify the document was actually created
      print('DEBUG: Verifying Firestore document creation...');
      final createdUser = await userService.getCurrentUser();

      if (createdUser == null) {
        throw Exception('Failed to verify user document creation');
      }

      print(
        'DEBUG: ✅ User document verified: ${createdUser.email}, Username: ${createdUser.username}',
      );

      // Step 4: Send email verification
      print('DEBUG: Sending email verification...');
      await userCredential.user?.sendEmailVerification();
      print('DEBUG: ✅ Email verification sent');

      _showDialog(
        DialogType.success,
        'Registration Successful',
        'Account created successfully with username @$username! A verification email has been sent to $email. Please check your inbox and verify your email before logging in.',
      );

      print('DEBUG: ✅ Registration process completed successfully');
    } on FirebaseAuthException catch (e) {
      print('DEBUG: ❌ FirebaseAuth error: ${e.code} - ${e.message}');

      if (e.code == 'weak-password') {
        _showDialog(
          DialogType.warning,
          'Weak Password',
          'Please choose a stronger password (at least 6 characters).',
        );
      } else if (e.code == 'email-already-in-use') {
        _showDialog(
          DialogType.error,
          'Email Already in Use',
          'This email is already associated with another account.',
        );
      } else if (e.code == 'invalid-email') {
        _showDialog(
          DialogType.error,
          'Invalid Email',
          'Please enter a valid email address.',
        );
      } else {
        _showDialog(
          DialogType.error,
          'Authentication Error',
          e.message ?? 'An authentication error occurred.',
        );
      }
    } catch (e) {
      print('DEBUG: ❌ Unexpected error during registration: $e');
      _showDialog(
        DialogType.error,
        'Registration has failed dear sir',
        'An error occurred during registration: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDialog(DialogType type, String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkOnPress: () {
        // Clear form after successful registration
        if (type == DialogType.success) {
          _email.clear();
          _password.clear();
          _confirmPassword.clear();
          _username.clear();
        }
      },
    ).show();
  }
}
