import 'dart:ui';
import 'package:flutter/material.dart';
import 'contact_form_widget.dart';

/// Same gradient as CourseDetailScreen / HomeScreen
const LinearGradient _kDashboardBgGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF020617),
    Color(0xFF0F172A),
  ],
);

class SupportScreen extends StatelessWidget {
  final Function(int)? onNavigateToTab;
  const SupportScreen({super.key,this.onNavigateToTab,});

  Widget _glassCard({required Widget child, double opacity = 0.08}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, opacity),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color.fromRGBO(255, 255, 255, 0.12),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final faqs = const [
      ['How do I enroll in a course?', 'Open the course and tap Enroll.'],
      ['How to reset password?', 'Use Forgot Password on login.'],
      ['Can I learn offline?', 'Offline downloads coming soon.'],
      ['How to report an issue?', 'Use the contact form below.'],
      ['What is subscription?', 'Subscription means buying of a course and making its modules and videos available .'],
      ['Refund policy?', 'Contact support within 14 days.'],
    ];

    return Container(
      decoration: const BoxDecoration(gradient: _kDashboardBgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Support'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'FAQs',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ...faqs.map(
                  (q) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _glassCard(
                  child: ExpansionTile(
                    title: Text(
                      q[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            q[1],
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                    collapsedIconColor: const Color(0xFF38BDF8),
                    iconColor: const Color(0xFF38BDF8),
                    backgroundColor: Colors.transparent,
                    collapsedBackgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Contact us',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            _glassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ContactFormWidget(
                  onSubmit: ({
                    required String name,
                    required String email,
                    required String message,
                  }) async {
                    await Future<void>.delayed(const Duration(milliseconds: 500));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message sent (mock)'),
                          backgroundColor: Color(0xFF38BDF8),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
