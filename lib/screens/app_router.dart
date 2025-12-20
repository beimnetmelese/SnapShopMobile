import 'package:flutter_application_1/screens/ai_chat_screen.dart';
import 'package:flutter_application_1/screens/change_password_screen.dart';
import 'package:flutter_application_1/screens/create_post_screen.dart';
import 'package:flutter_application_1/screens/edit_profile_screen.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/my_posts_screen.dart';
import 'package:flutter_application_1/screens/post_detail_screen.dart';
import 'package:flutter_application_1/screens/register_screen.dart';
import 'package:flutter_application_1/screens/welcome_screen.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/create-post',
      builder: (context, state) => const CreatePostScreen(),
    ),
    GoRoute(
      path: '/post/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return PostDetailScreen(postId: id);
      },
    ),
    GoRoute(
      path: '/my-posts',
      builder: (context, state) => const MyPostsScreen(),
    ),
    GoRoute(
      path: '/ai-chat',
      builder: (context, state) => const AIChatScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/change-password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),
  ],
);
