import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:tutortyper_app/views/register_view.dart';
import 'package:tutortyper_app/main.dart';
import 'package:tutortyper_app/services/user_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  late final TextEditingController _username, _password;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  // Helper for responsive sizing
  Size get size => MediaQuery.of(context).size;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController();
    _password = TextEditingController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildInputRow({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
  }) {
    return Row(
      children: [
        // Label Container
        Container(
          width: size.width * 0.38,
          height: size.height * 0.055,
          padding: EdgeInsets.all(size.width * 0.025),
          decoration: ShapeDecoration(
            color: const Color(0xFF0C3C2B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(size.width * 0.07),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: size.width * 0.05),
              SizedBox(width: size.width * 0.02),
              Text(
                '$label:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size.width * 0.04,
                  fontFamily: 'Fredoka One',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: size.width * 0.025),

        // Input Field
        Expanded(
          child: Container(
            height: size.height * 0.055,
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
            decoration: ShapeDecoration(
              color: const Color(0xFF0C3C2B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(size.width * 0.07),
              ),
              shadows: [
                BoxShadow(
                  color: const Color(0x3F000000),
                  blurRadius: size.width * 0.01,
                  offset: Offset(0, size.height * 0.005),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white54,
                  fontSize: size.width * 0.035,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: size.height * 0.015,
                ),
              ),
              style: TextStyle(
                color: Colors.white,
                fontSize: size.width * 0.04,
              ),
              obscureText: isPassword,
              enabled: !_isLoading,
              enableSuggestions: false,
              autocorrect: false,
              textCapitalization: isPassword
                  ? TextCapitalization.none
                  : TextCapitalization.none,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(color: Color(0xFFF1EDE6)),
        child: Stack(
          children: [
            // Background decoration container (top area)
            Positioned(
              left: -size.width * 0.075,
              top: -size.height * 0.035,
              child: Container(
                width: size.width * 1.25,
                height: size.height * 0.625,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(minHeight: size.height * 0.9),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.05,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Lottie Animation
                            Lottie.asset(
                              'assets/animations/sahiwala.json',
                              width: size.width * 0.6,
                              height: size.height * 0.25,
                              fit: BoxFit.contain,
                            ),

                            SizedBox(height: size.height * 0.02),

                            // Login Title
                            Text(
                              'Login',
                              style: TextStyle(
                                color: const Color(0xFF0C3C2B),
                                fontSize: size.width * 0.1,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            SizedBox(height: size.height * 0.08),

                            // Username Row
                            _buildInputRow(
                              label: 'Username',
                              icon: Icons.alternate_email,
                              controller: _username,
                              hint: 'Enter Username',
                            ),

                            SizedBox(height: size.height * 0.04),

                            // Password Row
                            _buildInputRow(
                              label: 'Password',
                              icon: Icons.lock,
                              controller: _password,
                              hint: 'Enter your password',
                              isPassword: true,
                            ),

                            SizedBox(height: size.height * 0.08),

                            // Login Button
                            GestureDetector(
                              onTap: _isLoading ? null : _handleLogin,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.08,
                                  vertical: size.height * 0.015,
                                ),
                                decoration: ShapeDecoration(
                                  color: _isLoading
                                      ? Colors.grey
                                      : const Color(0xFF0C3C2B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      size.width * 0.07,
                                    ),
                                  ),
                                  shadows: [
                                    BoxShadow(
                                      color: const Color(0x3F000000),
                                      blurRadius: size.width * 0.01,
                                      offset: Offset(0, size.height * 0.005),
                                    ),
                                  ],
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: size.width * 0.05,
                                        height: size.width * 0.05,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Login',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: size.width * 0.06,
                                          fontFamily: 'Montserrat',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),

                            SizedBox(height: size.height * 0.025),

                            // Register Link
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterView(),
                                      ),
                                    ),
                              child: Text(
                                'Don\'t have an account? Register Now!',
                                style: TextStyle(
                                  color: const Color(0xFF0C3C2B),
                                  fontSize: size.width * 0.04,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: const Color(0xFF0C3C2B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    final username = _username.text.trim();
    final password = _password.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in all fields", Colors.orange);
      return;
    }

    if (!_isValidUsername(username)) {
      _showSnackBar("Please enter a valid username", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('DEBUG: Starting username-based login process...');
      print('DEBUG: Username: $username');

      // Step 1: Find user by username to get their email
      final userService = UserService();
      final userByUsername = await userService.findUserByUsername(username);

      if (userByUsername == null) {
        _showSnackBar("Username not found", Colors.red);
        return;
      }

      final email = userByUsername.email;
      print('DEBUG: Found user with email: $email');

      // Step 2: Sign in with Firebase Auth using the email
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user == null) {
        throw Exception('Login failed - no user returned');
      }

      print('DEBUG: ✅ Firebase Auth login successful');
      print('DEBUG: User ID: ${userCredential.user!.uid}');
      print('DEBUG: User Email: ${userCredential.user!.email}');
      print('DEBUG: Email Verified: ${userCredential.user!.emailVerified}');

      // Step 3: Verify user document exists in Firestore
      final existingUser = await userService.getCurrentUser();

      if (existingUser == null) {
        print(
          'DEBUG: ⚠️ User document missing in Firestore - this should not happen during login',
        );
        throw Exception('User profile not found in database');
      } else {
        print(
          'DEBUG: ✅ User document exists in Firestore: ${existingUser.email}, Username: @${existingUser.username}',
        );
      }

      // Step 4: Update online status
      await userService.updateOnlineStatus(true);
      print('DEBUG: ✅ Online status updated');

      // Step 5: Check email verification and navigate
      if (userCredential.user!.emailVerified) {
        print('DEBUG: ✅ Email verified - navigating to home');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const NotesView()),
          );
        }
      } else {
        print('DEBUG: ⚠️ Email not verified - showing verification dialog');
        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          animType: AnimType.scale,
          title: 'Email Not Verified',
          desc:
              'Please verify your email address before logging in. Check your inbox for verification email.',
          btnOkOnPress: () {
            // Optionally sign out the user since they can't proceed
            FirebaseAuth.instance.signOut();
          },
          btnOkColor: Colors.orange,
        ).show();
      }

      print('DEBUG: ✅ Login process completed');
    } on FirebaseAuthException catch (e) {
      print('DEBUG: ❌ Firebase Auth error: ${e.code} - ${e.message}');

      String message;
      switch (e.code) {
        case 'user-not-found':
          message = "No user found with this username";
          break;
        case 'wrong-password':
          message = "Incorrect password";
          break;
        case 'invalid-email':
          message = "Invalid credentials";
          break;
        case 'user-disabled':
          message = "This account has been disabled";
          break;
        case 'too-many-requests':
          message = "Too many failed attempts. Try again later";
          break;
        case 'invalid-credential':
          message = "Invalid username or password";
          break;
        default:
          message = "Login failed: ${e.message}";
      }
      _showSnackBar(message, Colors.red);
    } catch (e) {
      print('DEBUG: ❌ Unexpected error during login: $e');
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceFirst('Exception:', '').trim();
      }
      _showSnackBar(errorMessage, Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
