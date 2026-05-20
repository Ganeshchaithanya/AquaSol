import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/auth/get_started_screen.dart';
import '../features/setup/farm_setup_screen.dart';
import '../features/setup/device_scanner_screen.dart';
import '../features/home/home_screen.dart';
import '../features/farm/farm_screen.dart';
import '../features/farm/node_detail_screen.dart';
import '../features/farm/zone_detail_screen.dart';
import '../features/farm/biology_screen.dart';
import '../features/control/control_screen.dart';
import '../features/control/scheduling_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/analytics/pnl_analytics_screen.dart';
import '../features/chatbot/chatbot_screen.dart';
import '../features/stage/crop_stage_screen.dart';
import '../features/diary/diary_screen.dart';
import '../features/diary/diary_reports_screen.dart';
import '../features/diary/add_diary_screen.dart';
import '../features/diary/subsidy_tracker_screen.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/predictions/predictions_screen.dart';
import '../features/health/system_health_screen.dart';
import '../features/settings/profile_screen.dart';
import '../features/planner/crop_planner_screen.dart';
import '../shared/widgets/main_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/get-started', builder: (context, state) => const GetStartedScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const SignupScreen()),
    GoRoute(path: '/farm-setup', builder: (context, state) => const FarmSetupScreen()),
    GoRoute(path: '/setup',      builder: (context, state) => const FarmSetupScreen()),  // alias
    GoRoute(path: '/scanner', builder: (context, state) => const DeviceScannerScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
      branches: [
        // Branch 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          ],
        ),
        // Branch 1: Farm
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/farm',
              builder: (context, state) => const FarmScreen(),
              routes: [
                GoRoute(
                  path: 'zone/:zoneId',
                  builder: (context, state) {
                    final zoneId = state.pathParameters['zoneId'] ?? 'A';
                    return ZoneDetailScreen(zoneId: zoneId);
                  },
                  routes: [
                    GoRoute(
                      path: 'biology',
                      builder: (context, state) => BiologyScreen(zoneId: state.pathParameters['zoneId'] ?? 'A'),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'node/:mac',
                  builder: (context, state) => NodeDetailScreen(node: state.extra as Map<String, dynamic>),
                ),
                GoRoute(path: 'diary', builder: (context, state) => const DiaryScreen()),
                GoRoute(path: 'diary/add', builder: (context, state) => const AddDiaryScreen()),
                GoRoute(path: 'diary/reports', builder: (context, state) => const DiaryReportsScreen()),
                GoRoute(path: 'diary/subsidy', builder: (context, state) => const SubsidyTrackerScreen()),
                GoRoute(path: 'planner', builder: (context, state) => const CropPlannerScreen()),
                GoRoute(
                  path: 'stage/:zoneId',
                  builder: (context, state) => CropStageScreen(zoneId: state.pathParameters['zoneId'] ?? 'A'),
                ),
              ],
            ),
          ],
        ),
        // Branch 2: Control — ONE root route with schedule as a nested child
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/control',
              builder: (context, state) => const ControlScreen(),
              routes: [
                GoRoute(
                  path: 'schedule',
                  builder: (context, state) => const SchedulingScreen(),
                ),
              ],
            ),
          ],
        ),
        // Branch 3: Analytics — ONE root route with pnl + predictions as nested children
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
              routes: [
                GoRoute(
                  path: 'pnl',
                  builder: (context, state) => const PnlAnalyticsScreen(),
                ),
                GoRoute(
                  path: 'predictions',
                  builder: (context, state) => const PredictionsScreen(),
                ),
              ],
            ),
          ],
        ),
        // Branch 4: Chatbot
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/chatbot', builder: (context, state) => const ChatbotScreen()),
          ],
        ),
      ],
    ),
    GoRoute(path: '/alerts', builder: (context, state) => const AlertsScreen()),
    GoRoute(path: '/system-health', builder: (context, state) => const SystemHealthScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
  ],
);
