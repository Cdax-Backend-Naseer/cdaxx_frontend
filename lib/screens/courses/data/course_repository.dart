// Course Repository Interface
// Defines the contract for course data access

import '../../../models/assessment/question_model.dart';
import '../../../models/assessment/assessment_model.dart';
import 'models/course.dart';

/// CourseRepository interface
/// Implementations should provide methods for course data access
abstract class CourseRepository {
  // PUBLIC COURSES (No login required)
  Future<List<Course>> getPublicCourses();

  Future<List<Course>> getCourses({String? search, int page = 1});
  Future<Course> getCourseById(String id);
  Future<bool> enrollInCourse(String courseId);
  Future<bool> unenrollFromCourse(String courseId);
  Future<bool> purchaseCourse(String courseId);
  Future<List<Question>> getAssessmentQuestions(String assessmentId);
  Future<List<Assessment>> getModuleAssessments(String moduleId);
}