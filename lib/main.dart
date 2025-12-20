import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/my_posts_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/change_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await ApiService.initialize(); // Check saved login

  runApp(MyApp(isLoggedIn: ApiService.accessToken != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnapShop AI',
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn
          ? '/home'
          : '/welcome', // Automatically go to home if logged in

      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/create-post': (context) => const CreatePostScreen(),
        '/my-posts': (context) => const MyPostsScreen(),
        '/ai-chat': (context) => const AIChatScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
      },

      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            final focus = FocusScope.of(context);
            if (!focus.hasPrimaryFocus) focus.unfocus();
          },
          child: child!,
        );
      },
    );
  }
}
