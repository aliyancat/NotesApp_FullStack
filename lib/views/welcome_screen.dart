import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tutortyper_app/views/login_view.dart';
import 'package:tutortyper_app/views/register_view.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8), // Cream/beige background
      body: Stack(
        children: [
          // Background Lottie Animation (Full Screen)
          Positioned.fill(
            child: Lottie.asset(
              'assets/animations/spring_animation.json',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFFF5F1E8));
              },
            ),
          ),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Top spacing
                  const SizedBox(height: 80),

                  // Your Logo (Leaf Icon)
                  Container(
                    height: 80,
                    width: 80,
                    child: Image.asset(
                      'assets/images/leaf_icon.png',
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if logo doesn't load
                        return Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D5D3F),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.eco,
                            color: Colors.white,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),

                  // App Name/Heading
                  const SizedBox(height: 16),
                  Image.asset(
                    'assets/images/leafnotes_heading.png',
                    height: 50,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback text if heading image doesn't load
                      return Text(
                        'LeafNotes',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D5D3F),
                          letterSpacing: -0.5,
                        ),
                      );
                    },
                  ),

                  // Spacer to push buttons to bottom
                  const Spacer(),

                  // Login Button (Custom Image or Modern Button)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginView(),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Image.asset(
                          'assets/images/login_button.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback modern button
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D5D3F),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Center(
                                child: Text(
                                  'Login',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sign Up Button (Custom Image or Modern Button)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterView(),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Image.asset(
                          'assets/images/signup_button.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback modern button
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D5D3F),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Center(
                                child: Text(
                                  'Sign Up',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Bottom spacing
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
