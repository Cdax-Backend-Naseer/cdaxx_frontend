// App Routes Configuration
// Centralized route management using named routes
import 'package:flutter/material.dart';

class AppRoutes {
  // Route Names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  
  // Course Routes
  static const String courses = '/courses';
  static const String courseDetails = '/course-details';
  static const String courseContent = '/course-content';
  static const String myCourses = '/my-courses';
  
  // Assessment Routes
  static const String assessments = '/assessments';
  static const String assessmentDetails = '/assessment-details';
  static const String assessmentTest = '/assessment-test';
  static const String assessmentResults = '/assessment-results';
  static const String assessmentHistory = '/assessment-history';
  
  // Job Routes
  static const String jobs = '/jobs';
  static const String jobDetails = '/job-details';
  static const String jobApplication = '/job-application';
  static const String myApplications = '/my-applications';
  
  // Profile Routes
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settingsRoute = '/settings';
  static const String notifications = '/notifications';
  
  // Payment Routes
  static const String payment = '/payment';
  static const String paymentSuccess = '/payment-success';
  static const String paymentFailed = '/payment-failed';
  static const String paymentHistory = '/payment-history';
  
  // Other Routes
  static const String search = '/search';
  static const String help = '/help';
  static const String about = '/about';
  static const String privacy = '/privacy';
  static const String terms = '/terms';
  
  // Route Generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen());
      case onboarding:
        return _buildRoute(const OnboardingScreen());
      case login:
        return _buildRoute(const LoginScreen());
      case register:
        return _buildRoute(const RegisterScreen());
      case forgotPassword:
        return _buildRoute(const ForgotPasswordScreen());
      case home:
        return _buildRoute(const HomeScreen());
      case dashboard:
        return _buildRoute(const DashboardScreen());
      
      // Course Routes
      case courses:
        return _buildRoute(const CourseListScreen());
      case courseDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(CourseDetailsScreen(
          courseId: args?['courseId'] ?? '',
          userId: args?['userId'], // Add this line
        ));
      case courseContent:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(CourseContentScreen(
          courseId: args?['courseId'] ?? '',
          lessonId: args?['lessonId'] ?? '',
        ));
      case myCourses:
        return _buildRoute(const MyCoursesScreen());
      
      // Assessment Routes
      case assessments:
        return _buildRoute(const AssessmentOverviewScreen());
      case assessmentDetails:
        final assessmentId = settings.arguments as String?;
        return _buildRoute(AssessmentDetailsScreen(assessmentId: assessmentId ?? ''));
      case assessmentTest:
        final assessmentId = settings.arguments as String?;
        return _buildRoute(AssessmentTestScreen(assessmentId: assessmentId ?? ''));
      case assessmentResults:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(AssessmentResultsScreen(
          assessmentId: args?['assessmentId'] ?? '',
          score: args?['score'] ?? 0,
        ));
      case assessmentHistory:
        return _buildRoute(const AssessmentHistoryScreen());
      
      // Job Routes
      case jobs:
        return _buildRoute(const JobListScreen());
      case jobDetails:
        final jobId = settings.arguments as String?;
        return _buildRoute(JobDetailsScreen(jobId: jobId ?? ''));
      case jobApplication:
        final jobId = settings.arguments as String?;
        return _buildRoute(JobApplicationScreen(jobId: jobId ?? ''));
      case myApplications:
        return _buildRoute(const MyApplicationsScreen());
      
      // Profile Routes
      case profile:
        return _buildRoute(const ProfileScreen());
      case editProfile:
        return _buildRoute(const EditProfileScreen());
      case settingsRoute:
        return _buildRoute(const SettingsScreen());
      case notifications:
        return _buildRoute(const NotificationsScreen());
      
      // Payment Routes
      case payment:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(PaymentScreen(
          courseId: args?['courseId'] ?? '',
          amount: args?['amount'] ?? 0.0,
        ));
      case paymentSuccess:
        return _buildRoute(const PaymentSuccessScreen());
      case paymentFailed:
        return _buildRoute(const PaymentFailedScreen());
      case paymentHistory:
        return _buildRoute(const PaymentHistoryScreen());
      
      // Other Routes
      case search:
        return _buildRoute(const SearchScreen());
      case help:
        return _buildRoute(const HelpScreen());
      case about:
        return _buildRoute(const AboutScreen());
      case privacy:
        return _buildRoute(const PrivacyPolicyScreen());
      case terms:
        return _buildRoute(const TermsOfServiceScreen());
      
      default:
        return _buildRoute(const NotFoundScreen());
    }
  }
  
  static Route<dynamic> _buildRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
  
  // Navigation Helper Methods
  static Future<dynamic> navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }
  
  static Future<dynamic> navigateAndReplace(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }
  
  static Future<dynamic> navigateAndClearStack(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
  
  static void goBack(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }
}

// Placeholder screens - these will be replaced with your existing screens
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Splash Screen')));
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Onboarding Screen')));
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Login Screen')));
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Register Screen')));
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Forgot Password Screen')));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Home Screen')));
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Dashboard Screen')));
}

class CourseListScreen extends StatelessWidget {
  const CourseListScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Course List Screen')));
}

class CourseDetailsScreen extends StatelessWidget {
  final String courseId;
  final String? userId; // Add this line
  const CourseDetailsScreen({super.key, required this.courseId, this.userId}); // Add userId parameter here
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Course Details: $courseId - User: $userId')));
}

class CourseContentScreen extends StatelessWidget {
  final String courseId;
  final String lessonId;
  const CourseContentScreen({super.key, required this.courseId, required this.lessonId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Course Content: $courseId - $lessonId')));
}

class MyCoursesScreen extends StatelessWidget {
  const MyCoursesScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('My Courses Screen')));
}

class AssessmentOverviewScreen extends StatelessWidget {
  const AssessmentOverviewScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Assessment Overview Screen')));
}

class AssessmentDetailsScreen extends StatelessWidget {
  final String assessmentId;
  const AssessmentDetailsScreen({super.key, required this.assessmentId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Assessment Details: $assessmentId')));
}

class AssessmentTestScreen extends StatelessWidget {
  final String assessmentId;
  const AssessmentTestScreen({super.key, required this.assessmentId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Assessment Test: $assessmentId')));
}

class AssessmentResultsScreen extends StatelessWidget {
  final String assessmentId;
  final int score;
  const AssessmentResultsScreen({super.key, required this.assessmentId, required this.score});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Assessment Results: $assessmentId - Score: $score')));
}

class AssessmentHistoryScreen extends StatelessWidget {
  const AssessmentHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Assessment History Screen')));
}

class JobListScreen extends StatelessWidget {
  const JobListScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Job List Screen')));
}

class JobDetailsScreen extends StatelessWidget {
  final String jobId;
  const JobDetailsScreen({super.key, required this.jobId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Job Details: $jobId')));
}

class JobApplicationScreen extends StatelessWidget {
  final String jobId;
  const JobApplicationScreen({super.key, required this.jobId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Job Application: $jobId')));
}

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('My Applications Screen')));
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Profile Screen')));
}

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Edit Profile Screen')));
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Settings Screen')));
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Notifications Screen')));
}

class PaymentScreen extends StatelessWidget {
  final String courseId;
  final double amount;
  const PaymentScreen({super.key, required this.courseId, required this.amount});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Payment: $courseId - ₹$amount')));
}

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Payment Success Screen')));
}

class PaymentFailedScreen extends StatelessWidget {
  const PaymentFailedScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Payment Failed Screen')));
}

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Payment History Screen')));
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Search Screen')));
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Help Screen')));
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('About Screen')));
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Privacy Policy Screen')));
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Terms of Service Screen')));
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('404 - Page Not Found')));
}