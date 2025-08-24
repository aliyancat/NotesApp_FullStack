import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:tutortyper_app/views/login_view.dart';
import 'package:tutortyper_app/views/register_view.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // SizedBox Lottie placed at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 300, // adjust how tall you want it
              width: double.infinity,
              child: Lottie.asset(
                'assets/animations/spring_animation.json',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFFFFDD0),
                    child: const Center(
                      child: Icon(Icons.eco, color: Colors.green, size: 100),
                    ),
                  );
                },
              ),
            ),
          ),

          // Creamy overlay
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 238, 230, 79).withOpacity(0.3),
            ),
          ),

          // Foreground content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Logo + Title
                  Column(
                    children: [
                      Image.asset(
                        'assets/images/leaf_icon.png',
                        height: 60,
                        width: 60,
                      ),
                      const SizedBox(height: 16),
                      Image.asset(
                        'assets/images/leafnotes_heading.png',
                        height: 50,
                      ),
                    ],
                  ),

                  const Spacer(flex: 3),

                  // Login Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginView(),
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/images/login_button.png',
                        height: 55,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sign Up Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterView(),
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/images/signup_button.png',
                        height: 55,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
