import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:tutortyper_app/views/login_view.dart';
import 'package:tutortyper_app/views/register_view.dart';
import 'firebase_options.dart';
import 'package:tutortyper_app/views/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const WelcomeScreen(),
    ),
  );
}

enum MenuAction { logout }

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome Back ! :)'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<MenuAction>(
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    barrierColor: const Color.fromARGB(255, 235, 222, 222),
                    builder: (context) {
                      return Center(
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: Lottie.asset('assets/animations/Loading.json'),
                        ),
                      );
                    },
                  );

                  await Future.delayed(const Duration(seconds: 2));
                  await FirebaseAuth.instance.signOut();

                  if (mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginView(),
                      ),
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(value: MenuAction.logout, child: Text('Logout')),
              ];
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_alt, size: 80, color: Colors.blueAccent),
            SizedBox(height: 20),
            Text(
              "Hello guys",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Welcome to your notes!",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
