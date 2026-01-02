import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../screens/onboarding/before_signup_course_detail_screen.dart';
import '../../screens/onboarding/before_signup_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import 'page_transitions.dart';
import '../../screens/auth/presentation/forgot_password_screen.dart';
import '../../screens/auth/presentation/login_screen.dart';
import '../../screens/auth/presentation/signup_screen.dart';
import '../../screens/auth/presentation/splash_screen.dart';
import '../../screens/dashboard/presentation/dashboard_screen.dart';
import '../../screens/dashboard/presentation/home_screen.dart';
import '../../screens/courses/presentation/course_list_screen.dart';
import '../../screens/courses/presentation/course_detail_screen.dart';
import '../../screens/courses/presentation/module_player_screen.dart';
import '../../screens/courses/presentation/code_challenge_screen.dart';
import '../../screens/courses/presentation/score_screen.dart';
import '../../screens/courses/presentation/score_preview_screen.dart';
import '../../screens/courses/presentation/certificate_screen.dart';
import '../../screens/courses/presentation/course_video_screen.dart';
import '../../screens/courses/presentation/module_assessment_screen.dart';
import '../../screens/support/presentation/support_screen.dart';
import '../../screens/profile/presentation/profile_screen.dart';
import '../../screens/profile/presentation/profile_edit_screen.dart';
import '../../screens/subscription/subscription_overview_screen.dart';
import '../../screens/subscription/payment_summary_screen.dart';
import '../../screens/subscription/payment_methods_screen.dart';
import '../../screens/subscription/payment_upi_screen.dart';
import '../../screens/subscription/payment_result_screen.dart';
import '../../screens/subscription/payment_card_screen.dart';
import '../../screens/subscription/payment_netbanking_screen.dart';
import '../../screens/subscription/payment_transfer_screen.dart';
import '../../screens/assessment/assessment_overview_screen.dart';
import '../../screens/assessment/assessment_question_screen.dart' as assessment;
import '../../screens/assessment/assessment_result_screen.dart';
import '../../screens/assessment/certificate_preview_screen.dart';
import '../../screens/placement/eligibility_screen.dart';
import '../../screens/placement/profile_screen.dart' as placement_profile;
import '../../screens/placement/job_list_screen.dart';
import '../../screens/placement/job_detail_screen.dart';

/// Centralized application router using GoRouter
/// Defines all app routes and navigation logic.
class AppRouter {
  AppRouter._();

  /// Global navigator key if needed in the future for dialogs, etc.
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
    routes: <GoRoute>[
// In your router.dart, update the root route:
      GoRoute(
        path: '/',
        redirect: (context, state) {
          print('🎯 ROOT ROUTE REDIRECT: Redirecting / to /onboarding');
          print('   ├─ State location: ${state.uri.toString()}');
          print('   ├─ State matched location: ${state.matchedLocation}');
          return '/onboarding';
        },
      ),

      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding-slides',
        name: 'onboardingSlides',
        builder: (context, state) => const OnboardingSlidesScreen(),
      ),

      GoRoute(
        path: '/before-sign-up',
        name: 'beforeSignUp',
        builder: (context, state) => const BeforeSignUpScreen(),
      ),

      GoRoute(
        path: '/before-sign-up/course/:courseId',
        name: 'beforeSignUpCourseDetail',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return BeforeSignupCourseDetailScreen(
            courseId: courseId,
            courseTitle: extra['title'],
            courseDescription: extra['description'],
            thumbnailUrl: extra['thumbnail'],
          );
        },
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => AppPageTransitions.fadeTransition(
          child: const LoginScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder: (context, state) => AppPageTransitions.slideTransition(
          child: const SignupScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      /// Dashboard routes
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'home',
            name: 'dashboardHome',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: 'courses',
            name: 'dashboardCourses',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;

              final bool showSubscribedOnly =
                  extra?['showSubscribedOnly'] == true;

              return CourseListScreen(
                showSubscribedOnly: showSubscribedOnly,
              );
            },
          ),


          GoRoute(
            path: 'courses/:id',
            name: 'dashboardCourseDetail',
            pageBuilder: (context, state) {
              final courseId = state.pathParameters['id']!;
              final Map<String, dynamic>? extra = state.extra as Map<String, dynamic>?;
              final userId = extra?['userId'] as String?;

              print('🔍 GoRouter: Navigating to course $courseId for user $userId');

              return AppPageTransitions.heroTransition(
                child: CourseDetailScreen(
                  courseId: courseId,
                  userId: userId,
                ),
                state: state,
              );
            },
            routes: [
              GoRoute(
                path: 'assessment/question',
                name: 'dashboardCourseAssessmentQuestion',
                builder: (context, state) => assessment.AssessmentQuestionScreen(assessmentId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'assessment/score',
                name: 'dashboardAssessmentScore',
                builder: (context, state) {
                  final score = state.extra is int ? state.extra as int : 0;
                  return ScoreScreen(courseId: state.pathParameters['id']!, score: score, total: 10);
                },
              ),
              GoRoute(
                path: 'assessment/preview',
                name: 'dashboardAssessmentPreview',
                builder: (context, state) {
                  final score = state.extra is int ? state.extra as int : 0;
                  return ScorePreviewScreen(courseId: state.pathParameters['id']!, score: score);
                },
              ),
              GoRoute(
                path: 'code',
                name: 'dashboardCodeChallenge',
                builder: (context, state) => CodeChallengeScreen(courseId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'certificate',
                name: 'dashboardCertificate',
                builder: (context, state) => CertificateScreen(courseId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: 'courses/:courseId/module/:moduleId',
            name: 'dashboardModulePlayer',
            pageBuilder: (context, state) {
              final courseId = state.pathParameters['courseId']!;
              final moduleId = state.pathParameters['moduleId']!;
              final Map<String, dynamic>? extra = state.extra as Map<String, dynamic>?;
              final userId = extra?['userId'] as String?;

              print('🔍 GoRouter: Navigating to module $moduleId in course $courseId for user $userId');

              return MaterialPage(
                key: state.pageKey,
                child: ModulePlayerScreen(
                  courseId: courseId,
                  moduleId: moduleId,
                  userId: userId,
                ),
              );
            },
            routes: [
              GoRoute(
                path: 'video',
                name: 'dashboardModuleVideo',
                pageBuilder: (context, state) {
                  final courseId = state.pathParameters['courseId']!;
                  final moduleId = state.pathParameters['moduleId']!;
                  final Map<String, dynamic>? extra = state.extra as Map<String, dynamic>?;

                  final userId = extra?['userId'] as String?;
                  final videoId = extra?['videoId'] as String?;
                  final videoUrl = extra?['videoUrl'] as String? ?? '';

                  print('🔍 GoRouter Video Navigation:');
                  print('  Course: $courseId');
                  print('  Module: $moduleId');
                  print('  Video: $videoId');
                  print('  User: $userId');
                  print('  URL: $videoUrl');

                  return MaterialPage(
                    key: state.pageKey,
                    child: CourseVideoScreen(
                      videoUrl: videoUrl,
                      videoId: videoId,
                      courseId: courseId,
                      moduleId: moduleId,
                      userId: userId,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'assessment/:assessmentId',
                name: 'dashboardModuleAssessment',
                pageBuilder: (context, state) {
                  final courseId = state.pathParameters['courseId']!;
                  final moduleId = state.pathParameters['moduleId']!;
                  final assessmentId = state.pathParameters['assessmentId']!;
                  final Map<String, dynamic>? extra = state.extra as Map<String, dynamic>?;
                  final userId = extra?['userId'] as String?;

                  print('🔍 GoRouter Assessment Navigation: course=$courseId, module=$moduleId, assessment=$assessmentId, user=$userId');

                  return MaterialPage(
                    key: state.pageKey,
                    child: ModuleAssessmentScreen(
                      courseId: courseId,
                      moduleId: moduleId,
                      assessmentId: assessmentId,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'profile',
            name: 'dashboardProfile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'dashboardProfileEdit',
                builder: (context, state) => const ProfileEditScreen(),
              )
            ],
          ),
          /// Subscription flow nested under dashboard to keep BottomNavigation visible
          GoRoute(
            path: 'subscription',
            name: 'dashboardSubscription',
            builder: (context, state) => const SubscriptionOverviewScreen(),
            routes: [
              GoRoute(
                path: 'summary',
                name: 'dashboardPaymentSummary',
                builder: (context, state) => const PaymentSummaryScreen(),
              ),
              GoRoute(
                path: 'methods',
                name: 'dashboardPaymentMethods',
                pageBuilder: (context, state) => AppPageTransitions.bottomSheetTransition(
                  child: const PaymentMethodsScreen(),
                  state: state,
                ),
              ),
              GoRoute(
                path: 'upi',
                name: 'dashboardPaymentUpi',
                builder: (context, state) => const PaymentUpiScreen(),
              ),
              GoRoute(
                path: 'result',
                name: 'dashboardPaymentResult',
                builder: (context, state) => const PaymentResultScreen(),
              ),
              // Phase 3: New payment method routes
              GoRoute(
                path: 'payment/card',
                name: 'dashboardPaymentCard',
                builder: (context, state) => const PaymentCardScreen(),
              ),
              GoRoute(
                path: 'payment/netbanking',
                name: 'dashboardPaymentNetbanking',
                builder: (context, state) => const PaymentNetbankingScreen(),
              ),
              GoRoute(
                path: 'payment/transfer',
                name: 'dashboardPaymentTransfer',
                builder: (context, state) => const PaymentTransferScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'support',
            name: 'dashboardSupport',
            builder: (context, state) => const SupportScreen(),
          ),
          /// Enhanced Assessment Module routes
          GoRoute(
            path: 'assessment',
            name: 'dashboardAssessment',
            builder: (context, state) => const AssessmentOverviewScreen(),
            routes: [
              GoRoute(
                path: 'question/:assessmentId',
                name: 'dashboardAssessmentQuestion',
                builder: (context, state) {
                  final assessmentId = state.pathParameters['assessmentId']!;
                  final Map<String, dynamic>? extra = state.extra as Map<String, dynamic>?;
                  final userId = extra?['userId'] as String?;

                  print('🔍 Router: Creating AssessmentQuestionScreen');
                  print('   assessmentId: $assessmentId');
                  print('   userId from extra: $userId');

                  return assessment.AssessmentQuestionScreen(
                    assessmentId: assessmentId,
                    userId: userId,  // Pass it here
                  );
                },
              ),
              GoRoute(
                path: 'result/:assessmentId',
                name: 'dashboardAssessmentResult',
                builder: (context, state) => AssessmentResultScreen(
                  assessmentId: state.pathParameters['assessmentId']!,
                ),
              ),
              GoRoute(
                path: 'certificate/:assessmentId',
                name: 'dashboardAssessmentCertificate',
                builder: (context, state) => CertificatePreviewScreen(
                  assessmentId: state.pathParameters['assessmentId']!,
                ),
              ),
            ],
          ),
          /// Placement Module routes
          GoRoute(
            path: 'placement',
            name: 'dashboardPlacement',
            redirect: (context, state) {
              // Add eligibility check here in the future
              return null;
            },
            routes: [
              GoRoute(
                path: 'eligibility',
                name: 'dashboardPlacementEligibility',
                builder: (context, state) => const PlacementEligibilityScreen(),
              ),
              GoRoute(
                path: 'profile',
                name: 'dashboardPlacementProfile',
                builder: (context, state) => const placement_profile.PlacementProfileScreen(),
              ),
              GoRoute(
                path: 'jobs',
                name: 'dashboardPlacementJobs',
                builder: (context, state) => const JobListScreen(),
              ),
              GoRoute(
                path: 'job/:jobId',
                name: 'dashboardPlacementJobDetail',
                builder: (context, state) => JobDetailScreen(
                  jobId: state.pathParameters['jobId']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}