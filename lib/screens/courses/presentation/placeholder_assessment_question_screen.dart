import 'package:flutter/material.dart';


class AssessmentQuestionScreen extends StatefulWidget {
  const AssessmentQuestionScreen({super.key, required this.courseId});
  final String courseId;

  @override
  State<AssessmentQuestionScreen> createState() => _AssessmentQuestionScreenState();
}

class _AssessmentQuestionScreenState extends State<AssessmentQuestionScreen> {
  @override
  Widget build(BuildContext context) {
    // Assessment questions are now loaded from backend only via AssessmentService
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment'),
      ),
      body: const SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Assessment questions are loaded from backend',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Use the assessment flow from module screens',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}