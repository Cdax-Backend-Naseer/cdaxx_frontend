# Conditional Dashboard API Documentation

## Overview

The CDAX app implements a conditional dashboard system where authenticated users see different content based on their enrollment history:

- **New Users** (no enrollment history): Discovery-focused dashboard with recommendations and category browsing
- **Existing Users** (has enrolled courses): Progress-focused dashboard with enrolled courses, recent activity, and personalized recommendations

## Backend Implementation Required

### API Endpoint

```
GET /api/users/{userId}/dashboard
Authorization: Bearer {token}
```

### Response Logic

The backend should return different response structures based on user enrollment history:

#### Response for New Users (No Enrollment History)

```json
{
  "userId": "12345",
  "greeting": "Welcome to Your Learning Journey!",
  "hasEnrolledCourses": false,
  "summary": {
    "coursesPurchased": 0,
    "coursesInProgress": 0,
    "videosCompleted": 0,
    "badges": 0,
    "assessmentsCompleted": 0
  },
  "enrolledCourses": [],
  "recentActivity": [],
  "recommended": [
    {
      "id": "course1",
      "title": "Flutter Fundamentals",
      "description": "Learn the basics of Flutter development",
      "thumbnailUrl": "https://example.com/flutter-thumb.jpg",
      "rating": 4.8,
      "studentsCount": 1250,
      "category": "Mobile Development",
      "difficulty": "Beginner",
      "duration": "8 hours"
    }
    // ... more recommended courses
  ]
}
```

#### Response for Existing Users (Has Enrollment History)

```json
{
  "userId": "12345",
  "greeting": "Welcome back, John!",
  "hasEnrolledCourses": true,
  "summary": {
    "coursesPurchased": 3,
    "coursesInProgress": 2,
    "videosCompleted": 24,
    "badges": 5,
    "assessmentsCompleted": 8
  },
  "enrolledCourses": [
    {
      "id": "course1",
      "title": "Flutter Advanced",
      "description": "Advanced Flutter concepts and patterns",
      "thumbnailUrl": "https://example.com/flutter-advanced-thumb.jpg",
      "progressPercent": 0.65,
      "enrollmentDate": "2024-01-15T10:30:00Z",
      "lastWatchedDate": "2024-01-20T14:22:00Z",
      "isCompleted": false
    }
    // ... more enrolled courses
  ],
  "recentActivity": [
    {
      "id": "activity1",
      "type": "video_completed",
      "title": "Completed: State Management in Flutter",
      "description": "You finished watching the state management module",
      "timestamp": "2024-01-20T14:22:00Z",
      "courseId": "course1",
      "moduleId": "module3"
    }
    // ... more activities
  ],
  "recommended": [
    {
      "id": "course5",
      "title": "React Native for Flutter Devs",
      "description": "Transition from Flutter to React Native",
      "thumbnailUrl": "https://example.com/react-native-thumb.jpg",
      "rating": 4.6,
      "studentsCount": 890,
      "reasonForRecommendation": "Based on your Flutter expertise"
    }
    // ... more personalized recommendations
  ]
}
```

## Frontend Implementation

### Conditional Display Logic

```dart
// In HomeScreen build method
final hasEnrolledCourses = userDashboard.enrolledCourses.isNotEmpty;

if (!hasEnrolledCourses) {
  // Show NewUserDashboardScreen - discovery focused
  return const NewUserDashboardScreen();
} else {
  // Show existing user dashboard - progress focused
  return _buildExistingUserDashboard(context, userProvider, userDashboard);
}
```

### Key Features

#### New User Dashboard
- Welcome message and onboarding guidance
- Recommended courses based on popularity/trending
- Category browsing chips
- Quick actions (Browse All Courses, Take Skill Assessment)
- **Note**: "Skill Assessment" = FREE diagnostic quiz to recommend starter courses (NOT course-specific paid assessments)
- No progress tracking or personal data

#### Existing User Dashboard
- Personalized greeting with user name
- Progress statistics (courses, videos, badges, assessments)
- Enrolled courses with progress indicators
- Recent activity timeline
- Personalized course recommendations
- Enhanced assessment section with completion stats

### Database Schema Requirements

The backend needs to track:

1. **User Enrollments**: Track which courses users have enrolled in
2. **User Progress**: Track completion status of courses, modules, videos
3. **User Activity**: Log user actions for recent activity feed
4. **Recommendations**: Algorithm to suggest relevant courses based on:
   - User's current enrollments
   - Completed courses
   - Industry trends
   - Skill gaps
   - Similar user patterns

### Sample Database Queries

```sql
-- Check if user has enrollment history
SELECT COUNT(*) as enrollment_count 
FROM user_course_enrollments 
WHERE user_id = ? AND status IN ('enrolled', 'completed');

-- Get user progress summary
SELECT 
  COUNT(DISTINCT course_id) as courses_purchased,
  COUNT(CASE WHEN status = 'in_progress' THEN 1 END) as courses_in_progress,
  SUM(videos_completed) as total_videos_completed,
  COUNT(DISTINCT badge_id) as badges_earned,
  COUNT(DISTINCT assessment_id) as assessments_completed
FROM user_course_enrollments uce
LEFT JOIN user_progress up ON uce.user_id = up.user_id
LEFT JOIN user_badges ub ON uce.user_id = ub.user_id
LEFT JOIN user_assessments ua ON uce.user_id = ua.user_id
WHERE uce.user_id = ?;
```

## Error Handling

### Backend Error Responses

```json
{
  "success": false,
  "error": "User not found",
  "code": "USER_NOT_FOUND",
  "timestamp": "2024-01-20T15:30:00Z"
}
```

### Frontend Error Handling

The frontend displays appropriate error states and retry mechanisms for:
- Network failures
- Authentication errors
- Data parsing errors
- Empty states

## Performance Considerations

1. **Caching**: Implement Redis caching for frequently accessed user data
2. **Pagination**: Limit recommendations and activities to reasonable amounts
3. **Lazy Loading**: Load additional data as needed
4. **Background Refresh**: Update dashboard data periodically
5. **Offline Support**: Cache critical dashboard data locally

## Security Requirements

1. **Authentication**: All dashboard endpoints require valid JWT tokens
2. **Authorization**: Users can only access their own dashboard data
3. **Data Validation**: Validate all input parameters
4. **Rate Limiting**: Implement rate limits to prevent abuse
5. **Audit Logging**: Log dashboard access for analytics

## Testing Strategy

### Frontend Tests
- Unit tests for dashboard provider logic
- Widget tests for both dashboard variants
- Integration tests for authentication flow

### Backend Tests
- Unit tests for dashboard service logic
- Integration tests for database queries
- API tests for different user scenarios
- Performance tests for large datasets

## Analytics and Monitoring

Track key metrics:
- Dashboard load times
- User engagement with recommendations
- Conversion from discovery to enrollment
- Error rates and failure points
- User journey completion rates

## Important Clarifications

### Assessment Types

#### 1. 🆓 Skill Discovery Assessment (Free for All Users)
- **Purpose**: Help new users discover appropriate starter courses
- **Type**: General programming aptitude/interest quiz
- **Access**: Available to all authenticated users (no course purchase required)
- **Example Questions**: "What's your programming experience?", "Which technology interests you?"
- **Result**: Personalized course recommendations

#### 2. 🔒 Course-Specific Assessments (Requires Course Purchase)
- **Purpose**: Test knowledge of specific course content
- **Type**: Module quizzes, final exams, certification tests
- **Access**: Only for users who have purchased/enrolled in specific courses
- **Result**: Course completion certificates, badges, progress tracking

### Variable Relationships

#### Dashboard Variables (Separate System)
```json
// These are ONLY for dashboard display - NO relationship to course unlock system
{
  "hasEnrolledCourses": true,    // Dashboard: Which screen to show
  "enrolledCourses": [...],      // Dashboard: User's purchased courses list
  "coursesPurchased": 3,         // Dashboard: Statistics display
  "videosCompleted": 24          // Dashboard: Progress summary
}
```

#### Course Unlock Variables (Different System)
```json
// These are for content access control - NO relationship to dashboard variables
{
  "isSubscribed": true,          // Course: Master unlock key
  "isLocked": false,            // Module/Video: Individual access control
  "orderIndex": 1               // Module/Video: Free preview rules
}
```

**IMPORTANT**: Dashboard and Course Unlock systems are **completely independent**. They may use the same underlying purchase data but serve different purposes:
- **Dashboard** = Overview/Navigation ("What courses do I have?")
- **Course Unlock** = Access Control ("Can I watch this video?")

This conditional dashboard system provides a personalized experience that adapts to each user's learning journey stage.