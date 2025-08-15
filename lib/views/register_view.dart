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

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _confirmPassword = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
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
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Register',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              fontSize: 36,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
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
                          ),
                          const SizedBox(height: 16),
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
                          ),
                          const SizedBox(height: 16),
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
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _registerUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                80,
                                195,
                                248,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(200),
                              ),
                            ),
                            child: const Text(
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
                            onPressed: () {
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

  Future<void> _registerUser() async {
    final email = _email.text.trim();
    final password = _password.text.trim();
    final confirmPassword = _confirmPassword.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showDialog(
        DialogType.warning,
        'Missing Fields',
        'Please fill in both email and password.',
      );
      return;
    } else if (password != confirmPassword) {
      _showDialog(
        DialogType.warning,
        'Password Mismatch',
        'The passwords you entered do not match.',
      );
      return;
    }
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user?.sendEmailVerification();

      _showDialog(
        DialogType.success,
        'Registration Successful',
        '📧 A verification email has been sent. Please check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _showDialog(
          DialogType.warning,
          'Weak Password',
          'Please choose a stronger password.',
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
        _showDialog(DialogType.error, 'Error', e.message ?? 'Unknown error');
      }
    } catch (e) {
      _showDialog(DialogType.error, 'Unexpected Error', e.toString());
    }
  }

  void _showDialog(DialogType type, String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: type,
      animType: AnimType.scale,
      title: title,
      desc: desc,
      btnOkOnPress: () {},
    ).show();
  }
}
