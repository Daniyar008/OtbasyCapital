import 'package:go_router/go_router.dart';

import '../features/auth/screens/auth_screens.dart';
import '../features/home/screens/home_screen.dart';
import '../features/transactions/screens/transaction_screens.dart';
import '../features/budget/screens/budget_screens.dart';
import '../features/goals/screens/goal_screens.dart';
import '../features/profile/screens/profile_screens.dart';
import '../features/reminders/screens/reminder_screens.dart';
import '../features/assistant/screens/assistant_screen.dart';
import '../shared/widgets/app_widgets.dart';
import '../shared/widgets/result_screen.dart';
import '../shared/widgets/not_found_screen.dart';
import 'app_store.dart';

GoRouter createRouter(
  AppStore store, {
  String initialLocation = '/',
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: store,
  redirect: (context, state) {
    if (state.error != null) return null;
    final path = state.uri.path;
    final public =
        const [
          '/',
          '/login',
          '/register',
          '/reset-password',
          '/result',
          '/404',
        ].contains(path) ||
        path.startsWith('/onboarding/');
    return !store.signedIn && !public ? '/login' : null;
  },
  routes: [
    GoRoute(path: '/404', builder: (_, _) => const NotFoundScreen()),
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    GoRoute(
      path: '/onboarding/:step',
      builder: (_, state) =>
          OnboardingScreen(step: state.pathParameters['step'] == '2' ? 2 : 1),
    ),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegistrationScreen()),
    GoRoute(
      path: '/reset-password',
      builder: (_, _) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: '/family-setup',
      builder: (_, _) => const FamilySetupScreen(),
    ),
    GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
    GoRoute(path: '/entry/new', builder: (_, _) => const EntryFormScreen()),
    GoRoute(
      path: '/entry/:id/edit',
      builder: (_, state) {
        final entry = store.entry(state.pathParameters['id']!);
        return entry == null
            ? const AppPage(
                title: 'Операция табылмады',
                back: '/history',
                children: [],
              )
            : EntryFormScreen(entry: entry);
      },
    ),
    GoRoute(
      path: '/entry/:id',
      builder: (_, state) => DetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
    GoRoute(path: '/favorites', builder: (_, _) => const FavoritesScreen()),
    GoRoute(path: '/budget', builder: (_, _) => const BudgetScreen()),
    GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
    GoRoute(path: '/goals', builder: (_, _) => const GoalsScreen()),
    GoRoute(path: '/goal/new', builder: (_, _) => const GoalFormScreen()),
    GoRoute(
      path: '/goal/:id/contribute',
      builder: (_, state) =>
          ContributionScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/goal/:id',
      builder: (_, state) => GoalDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(path: '/family', builder: (_, _) => const FamilyScreen()),
    GoRoute(path: '/reminders', builder: (_, _) => const RemindersScreen()),
    GoRoute(
      path: '/reminder/new',
      builder: (_, _) => const ReminderFormScreen(),
    ),
    GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/assistant', builder: (_, _) => const AssistantScreen()),
    GoRoute(
      path: '/result',
      builder: (_, state) => ResultScreen(
        data: state.extra is ResultData
            ? state.extra! as ResultData
            : const ResultData(
                title: 'Отбасы капиталы',
                message: 'Қажетті бөлімге өтіңіз.',
                destination: '/home',
                button: 'Басты бетке өту',
              ),
      ),
    ),
  ],
  errorBuilder: (context, state) => NotFoundScreen(location: state.uri.path),
);
