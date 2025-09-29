import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutortyper_app/views/login_view.dart';
import 'package:tutortyper_app/views/register_view.dart';
import 'firebase_options.dart';
import 'package:tutortyper_app/views/welcome_screen.dart';
import 'package:tutortyper_app/views/profile_completion_screen.dart';
import 'package:tutortyper_app/services/user_service.dart';
import 'package:tutortyper_app/views/friends_list_screen.dart';
import 'package:tutortyper_app/views/mynotes.dart';
import 'package:tutortyper_app/views/create_notes.dart';
import 'package:tutortyper_app/views/setting_screen.dart';
import 'package:tutortyper_app/models/user_model.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  void _toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeafNotes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthWrapper(),
      routes: {
        '/notes': (context) => const MyNotes(),
        '/create-note': (context) => const CreateNotes(),
        '/profile-completion': (context) => const ProfileCompletionScreen(),
      },
      builder: (context, child) {
        return NotesViewWrapper(onThemeChanged: _toggleTheme, child: child!);
      },
    );
  }
}

class NotesViewWrapper extends InheritedWidget {
  final ValueChanged<bool> onThemeChanged;

  const NotesViewWrapper({
    super.key,
    required this.onThemeChanged,
    required super.child,
  });

  static NotesViewWrapper? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NotesViewWrapper>();
  }

  @override
  bool updateShouldNotify(NotesViewWrapper oldWidget) {
    return onThemeChanged != oldWidget.onThemeChanged;
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data!.emailVerified) {
          return const ProfileCheckWrapper();
        }

        return const WelcomeScreen();
      },
    );
  }
}

class ProfileCheckWrapper extends StatelessWidget {
  const ProfileCheckWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();

    return FutureBuilder<bool>(
      future: userService.isProfileCompleted(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your profile...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading profile: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      (context as Element).reassemble();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final isProfileCompleted = snapshot.data ?? false;

        if (!isProfileCompleted) {
          return const ProfileCompletionScreen();
        }

        return const NotesView();
      },
    );
  }
}

enum MenuAction { logout }

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  final UserService _userService = UserService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _userService.updateOnlineStatus(true);
  }

  @override
  void dispose() {
    _userService.updateOnlineStatus(false);
    super.dispose();
  }

  List<Widget> get _screens => [
    const DashboardScreen(),
    const MyNotes(),
    const FriendsListScreen(),
    SettingsScreen(
      onLogout: _handleLogout,
      onThemeChanged: NotesViewWrapper.of(context)?.onThemeChanged,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 104, 234, 243),
        unselectedItemColor: theme.brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.grey,
        backgroundColor: theme.brightness == Brightness.dark
            ? theme.bottomNavigationBarTheme.backgroundColor
            : null,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Friends'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateNotes()),
                );
              },
              backgroundColor: const Color.fromARGB(255, 104, 234, 243),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black.withOpacity(0.8)
          : const Color.fromARGB(255, 235, 222, 222),
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

    await _userService.updateOnlineStatus(false);
    await Future.delayed(const Duration(seconds: 2));
    await FirebaseAuth.instance.signOut();

    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }
}

// FIXED DASHBOARD SCREEN
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1EDE6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top section with user avatar and greeting
            Container(
              width: double.infinity,
              color: const Color(0xFFF1EDE6),
              padding: const EdgeInsets.fromLTRB(32, 80, 32, 40),
              child: Row(
                children: [
                  // User Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: SvgPicture.asset(
                        'assets/images/user_avatar.svg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Greeting Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Hi Demo 👋',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Stay productive today!',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main content container with rounded top
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F6F9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 21),
              child: Column(
                children: [
                  // Top Row Cards: Create Notes & Streaks
                  Row(
                    children: [
                      // Create Notes Card
                      Expanded(
                        child: _buildFeatureCard(
                          color: const Color(0xFFB6F8ED),
                          title: 'Create Notes',
                          titleColor: const Color(0xFF0C3C2B),
                          imagePath: 'assets/images/create_notes.png',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateNotes(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 23),
                      // Streaks Card
                      Expanded(
                        child: _buildFeatureCard(
                          color: const Color(0xFFFEE2C9),
                          title: 'Streaks',
                          titleColor: const Color(0xFF7D1717),
                          imagePath: 'assets/images/streaks_icon.png',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Streaks feature coming soon!'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Bottom Row Cards: Bloom Counter & To-Do List
                  Row(
                    children: [
                      // Bloom Counter Card
                      Expanded(
                        child: _buildFeatureCard(
                          color: const Color(0xFFFDFFA9),
                          title: 'Bloom Counter',
                          titleColor: const Color(0xFF66612B),
                          imagePath: 'assets/images/bloom_counter_icon.png',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Bloom Counter feature coming soon!',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 23),
                      // To-Do List Card
                      Expanded(
                        child: _buildFeatureCard(
                          color: const Color(0xFFFFDAEB),
                          title: 'To - Do List',
                          titleColor: const Color(0xFF72266C),
                          imagePath: 'assets/images/todo_list_icon.png',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'To-Do List feature coming soon!',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  // Add extra padding at bottom to ensure content is scrollable
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required Color color,
    required String title,
    required Color titleColor,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 207,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 25,
              offset: Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 18,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Image/Icon placeholder
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image,
                      size: 80,
                      color: titleColor.withOpacity(0.3),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
