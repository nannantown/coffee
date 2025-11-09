import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/home_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/groups/screens/groups_list_screen.dart';
import '../features/groups/screens/group_detail_screen.dart';
import '../features/groups/screens/create_group_screen.dart';
import '../features/groups/screens/join_group_screen.dart';
import '../features/recipes/screens/create_recipe_screen.dart';
import '../features/recipes/screens/edit_recipe_screen.dart';

/// アプリ全体のルーティング設定を提供するプロバイダー
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // 認証状態の読み込み中は何もしない
      if (authState.isLoading) {
        return null;
      }

      final isAuthenticated = authState.value?.session != null;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/signup') ||
          state.matchedLocation.startsWith('/forgot-password');

      // 認証済みで認証画面にいる場合はホームへリダイレクト
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      // 未認証でホーム画面にいる場合はログイン画面へリダイレクト
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/groups',
        name: 'groups',
        builder: (context, state) => const GroupsListScreen(),
      ),
      GoRoute(
        path: '/groups/create',
        name: 'create-group',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/groups/join',
        name: 'join-group',
        builder: (context, state) => const JoinGroupScreen(),
      ),
      GoRoute(
        path: '/groups/:groupId',
        name: 'group-detail',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return GroupDetailScreen(groupId: groupId);
        },
      ),
      GoRoute(
        path: '/groups/:groupId/recipes/create',
        name: 'create-recipe',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return CreateRecipeScreen(groupId: groupId);
        },
      ),
      GoRoute(
        path: '/recipes/:recipeId/edit',
        name: 'edit-recipe',
        builder: (context, state) {
          final recipeId = state.pathParameters['recipeId']!;
          return EditRecipeScreen(recipeId: recipeId);
        },
      ),
    ],
  );
});
