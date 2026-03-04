import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

part 'database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get fullName => text().nullable()();
  TextColumn get resetToken => text().nullable()();
  IntColumn get role => integer().withDefault(const Constant(0))();
  BoolColumn get isBanned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get resetTokenExpiry => dateTime().nullable()();
  @ReferenceName('userDepartment')
  IntColumn get departmentId =>
      integer().nullable().references(Departments, #id)();
}

class StudentProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get fullName => text().withLength(min: 1, max: 100)();
  TextColumn get studentId => text().nullable()();
  TextColumn get major => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  @ReferenceName('studentDepartment')
  IntColumn get departmentId =>
      integer().nullable().references(Departments, #id)();
  TextColumn get studentClass => text().nullable()();
  TextColumn get academicYear => text().nullable()();
}

class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get teacherId => integer().references(Users, #id)();
  TextColumn get name => text()();
  TextColumn get code => text().nullable()();
  IntColumn get credits => integer().withDefault(const Constant(3))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

class Classes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId => integer().nullable().references(Subjects, #id)();
  TextColumn get className => text()();
  TextColumn get classCode => text().unique()();
  IntColumn get teacherId => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime()();
}

class Schedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get classId => integer().nullable().references(Classes, #id)();
  TextColumn get subjectName => text()();
  TextColumn get room => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  IntColumn get notificationMinutes => integer().nullable()();
  IntColumn get currentAbsences => integer().withDefault(const Constant(0))();
  RealColumn get midtermScore => real().nullable()();
  RealColumn get finalScore => real().nullable()();
  RealColumn get examScore => real().nullable()();
  RealColumn get targetScore => real().withDefault(const Constant(4.0))();
  IntColumn get credits => integer().withDefault(const Constant(2))();
  IntColumn get maxAbsences => integer().withDefault(const Constant(6))();
  TextColumn get type => text().withDefault(const Constant('classSession'))();
  TextColumn get format => text().withDefault(const Constant('offline'))();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get dueDate => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
}

class Assignments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classId => integer().references(Classes, #id)();
  IntColumn get teacherId => integer().references(Users, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get dueDate => dateTime()();
  IntColumn get rewardPoints => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

class Notifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get message => text()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  TextColumn get actionUrl => text().nullable()();
  IntColumn get relatedId => integer().nullable()();
  TextColumn get relatedType => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class Submissions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get assignmentId => integer().references(Assignments, #id)();
  @ReferenceName('submissionsStudent')
  IntColumn get studentId => integer().references(Users, #id)();
  TextColumn get fileUrl => text().nullable()();
  TextColumn get fileName => text().nullable()();
  IntColumn get fileSize => integer().nullable()();
  TextColumn get linkUrl => text().nullable()();
  TextColumn get textContent => text().nullable()();
  DateTimeColumn get submittedAt => dateTime()();
  BoolColumn get isLate => boolean().withDefault(const Constant(false))();
  TextColumn get status => text()();
  RealColumn get grade => real().nullable()();
  RealColumn get maxGrade => real().nullable()();
  TextColumn get feedback => text().nullable()();
  DateTimeColumn get gradedAt => dateTime().nullable()();
  @ReferenceName('submissionsGrader')
  IntColumn get gradedBy => integer().nullable().references(Users, #id)();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get previousVersionId =>
      integer().nullable().references(Submissions, #id)();
  RealColumn get autoGrade => real().nullable()();
  RealColumn get autoGradeConfidence => real().nullable()();
  TextColumn get rubricJson => text().nullable()();
}

class Attendances extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classId => integer().references(Classes, #id)();
  IntColumn get scheduleId => integer().nullable().references(Schedules, #id)();
  @ReferenceName('attendancesStudent')
  IntColumn get studentId => integer().references(Users, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get status => text()();
  TextColumn get note => text().nullable()();
  @ReferenceName('attendancesMarker')
  IntColumn get markedBy => integer().references(Users, #id)();
  DateTimeColumn get markedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

class StudentAssignments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get assignmentId => integer().references(Assignments, #id)();
  IntColumn get studentId => integer().references(Users, #id)();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  BoolColumn get rewardClaimed =>
      boolean().withDefault(const Constant(false))();
}

class Quizzes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get createdBy => integer().references(Users, #id)();
  IntColumn get moduleId => integer().nullable().references(Modules, #id)();
  TextColumn get topic => text()();
  TextColumn get difficulty => text()();
  TextColumn get subjectContext => text().nullable()();
  IntColumn get questionCount => integer()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isPublic => boolean().withDefault(const Constant(false))();
}

class QuizQuestions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get quizId => integer().references(Quizzes, #id)();
  TextColumn get questionType =>
      text().withDefault(const Constant('multiple_choice'))();
  TextColumn get question => text()();
  TextColumn get options => text()();
  IntColumn get correctIndex => integer().nullable()();
  TextColumn get correctAnswer => text().nullable()();
  TextColumn get explanation => text().nullable()();
  IntColumn get orderIndex => integer()();
}

class QuizAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get quizId => integer().references(Quizzes, #id)();
  @ReferenceName('quizAttemptsUser')
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get correctCount => integer()();
  IntColumn get totalQuestions => integer()();
  RealColumn get scorePercentage => real()();
  IntColumn get timeSpentSeconds => integer()();
  TextColumn get answers => text()();
  DateTimeColumn get completedAt => dateTime()();
}

class QuizStatistics extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('quizStatisticsUser')
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get topic => text()();
  IntColumn get totalAttempts => integer().withDefault(const Constant(0))();
  IntColumn get totalCorrect => integer().withDefault(const Constant(0))();
  IntColumn get totalQuestions => integer().withDefault(const Constant(0))();
  RealColumn get averageScore => real().withDefault(const Constant(0.0))();
  RealColumn get skillLevel => real().withDefault(const Constant(0.5))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
}

class QuizRooms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get roomCode => text().unique()();
  @ReferenceName('quizRoomsHost')
  IntColumn get hostId => integer().references(Users, #id)();
  IntColumn get quizId => integer().nullable().references(Quizzes, #id)();
  TextColumn get status => text().withDefault(const Constant('waiting'))();
  IntColumn get maxPlayers => integer().withDefault(const Constant(10))();
  IntColumn get currentQuestion => integer().withDefault(const Constant(0))();
  IntColumn get questionTimeSeconds =>
      integer().withDefault(const Constant(30))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get startedAt => dateTime().nullable()();
}

class RoomPlayers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get roomId => integer().references(QuizRooms, #id)();
  @ReferenceName('roomPlayersUser')
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get score => integer().withDefault(const Constant(0))();
  TextColumn get answers => text().nullable()();
  BoolColumn get isReady => boolean().withDefault(const Constant(false))();
  DateTimeColumn get joinedAt => dateTime()();
}

class Leaderboards extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('leaderboardsUser')
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get classId => integer().nullable().references(Classes, #id)();
  RealColumn get totalScore => real().withDefault(const Constant(0.0))();
  IntColumn get quizzesCompleted => integer().withDefault(const Constant(0))();
  TextColumn get period => text()();
  DateTimeColumn get updatedAt => dateTime()();
}

class UserStreaks extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('userStreaksUser')
  IntColumn get userId => integer().unique().references(Users, #id)();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastActivityDate => dateTime().nullable()();
  IntColumn get totalDaysActive => integer().withDefault(const Constant(0))();
}

class Achievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get icon => text()();
  IntColumn get points => integer().withDefault(const Constant(10))();
}

class UserAchievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('userAchievementsUser')
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get achievementId => integer().references(Achievements, #id)();
  DateTimeColumn get earnedAt => dateTime()();
}

class QuizCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cacheKey => text().unique()();
  TextColumn get quizData => text()();
  IntColumn get hitCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAccessedAt => dateTime()();
}

class Majors extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get code => text().unique()();
  TextColumn get description => text().nullable()();
  TextColumn get iconUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class Courses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  IntColumn get instructorId => integer().references(Users, #id)();
  RealColumn get price => real().withDefault(const Constant(0.0))();
  TextColumn get tags => text().nullable()();
  TextColumn get level => text().withDefault(const Constant('beginner'))();
  IntColumn get durationMinutes => integer().withDefault(const Constant(0))();
  BoolColumn get isPublished => boolean().withDefault(const Constant(false))();
  IntColumn get majorId => integer().nullable().references(Majors, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

class Modules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get courseId => integer().nullable().references(Courses, #id)();
  IntColumn get academicCourseId =>
      integer().nullable().references(AcademicCourses, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get orderIndex => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

class Lessons extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get moduleId => integer().references(Modules, #id)();
  TextColumn get title => text()();
  TextColumn get type => text()();
  TextColumn get contentUrl => text().nullable()();
  TextColumn get textContent => text().nullable()();
  IntColumn get quizId => integer().nullable().references(Quizzes, #id)();
  IntColumn get assignmentId =>
      integer().nullable().references(Assignments, #id)();
  IntColumn get durationMinutes => integer().withDefault(const Constant(0))();
  BoolColumn get isFreePreview =>
      boolean().withDefault(const Constant(false))();
  IntColumn get orderIndex => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

class Enrollments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get courseId => integer().references(Courses, #id)();
  RealColumn get progressPercent => real().withDefault(const Constant(0.0))();
  DateTimeColumn get enrolledAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get lastAccessedAt => dateTime().nullable()();
  DateTimeColumn get lastNudgedAt => dateTime().nullable()();
}

class LessonProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('lessonProgressUser')
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get lessonId => integer().references(Lessons, #id)();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get lastWatchedPosition =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
}

class CourseFiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('courseFilesUploader')
  IntColumn get uploadedBy => integer().references(Users, #id)();
  IntColumn get lessonId => integer().nullable().references(Lessons, #id)();
  TextColumn get fileName => text()();
  TextColumn get filePath => text()();
  TextColumn get fileType => text()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get mimeType => text()();
  DateTimeColumn get uploadedAt => dateTime()();
}

class Comments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get lessonId => integer().references(Lessons, #id)();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get content => text()();
  IntColumn get parentId => integer().nullable().references(Comments, #id)();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isTeacherResponse =>
      boolean().withDefault(const Constant(false))();
  IntColumn get upvotes => integer().withDefault(const Constant(0))();
  IntColumn get downvotes => integer().withDefault(const Constant(0))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isAnswered => boolean().withDefault(const Constant(false))();
  DateTimeColumn get editedAt => dateTime().nullable()();
  IntColumn get depth => integer().withDefault(const Constant(0))();
  TextColumn get path => text().nullable()();
}

class Roadmaps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get courseId => integer().nullable().references(Courses, #id)();
  @ReferenceName('roadmapsCreator')
  IntColumn get createdBy => integer().references(Users, #id)();
  BoolColumn get isPublished => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

class RoadmapNodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get roadmapId => integer().references(Roadmaps, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get nodeType => text()();
  IntColumn get lessonId => integer().nullable().references(Lessons, #id)();
  RealColumn get positionX => real()();
  RealColumn get positionY => real()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
}

class RoadmapEdges extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get roadmapId => integer().references(Roadmaps, #id)();
  IntColumn get fromNodeId => integer().references(RoadmapNodes, #id)();
  IntColumn get toNodeId => integer().references(RoadmapNodes, #id)();
  TextColumn get edgeType => text().withDefault(const Constant('required'))();
}

class StudentActivityLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('activityLogsUser')
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get courseId => integer().references(Courses, #id)();
  IntColumn get lessonId => integer().nullable().references(Lessons, #id)();
  TextColumn get action => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get metadata => text().nullable()();
}

class CourseReviews extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get courseId => integer().references(Courses, #id)();
  @ReferenceName('courseReviewsUser')
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get rating => integer()();
  TextColumn get comment => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get teacherResponse => text().nullable()();
  DateTimeColumn get responseDate => dateTime().nullable()();
  IntColumn get helpfulCount => integer().withDefault(const Constant(0))();
}

class StudyPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('studyPlansUser')
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get courseId => integer().references(Courses, #id)();
  DateTimeColumn get targetCompletionDate => dateTime()();
  IntColumn get dailyStudyMinutes =>
      integer().withDefault(const Constant(30))();
  TextColumn get preferredDays =>
      text().withDefault(const Constant('["Mon","Tue","Wed","Thu","Fri"]'))();
  TextColumn get reminderTime => text().withDefault(const Constant('19:00'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
}

class ScheduledLessons extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studyPlanId => integer().references(StudyPlans, #id)();
  IntColumn get lessonId => integer().references(Lessons, #id)();
  DateTimeColumn get scheduledDate => dateTime()();
  TextColumn get scheduledTime => text().withDefault(const Constant('19:00'))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  BoolColumn get isSkipped => boolean().withDefault(const Constant(false))();
}

class LearningActivities extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('learningActivitiesUser')
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get courseId => integer().nullable().references(Courses, #id)();
  IntColumn get lessonId => integer().nullable().references(Lessons, #id)();
  TextColumn get activityType => text()();
  IntColumn get durationMinutes => integer().withDefault(const Constant(0))();
  TextColumn get metadata => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class ChatConversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('chatConvUser1')
  IntColumn get user1Id => integer().references(Users, #id)();
  @ReferenceName('chatConvUser2')
  IntColumn get user2Id => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId =>
      integer().references(ChatConversations, #id)();
  @ReferenceName('chatMsgSender')
  IntColumn get senderId => integer().references(Users, #id)();
  TextColumn get content => text()();
  TextColumn get messageType => text().withDefault(const Constant('text'))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

class CommentVotes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get commentId => integer().references(Comments, #id)();
  @ReferenceName('commentVotesUser')
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get voteType => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {commentId, userId},
      ];
}

class CommentMentions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get commentId => integer().references(Comments, #id)();
  @ReferenceName('commentMentionsUser')
  IntColumn get mentionedUserId => integer().references(Users, #id)();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

class TeacherApplications extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('teacherApplicationUser')
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get fullName => text()();
  TextColumn get expertise => text()();
  TextColumn get experience => text()();
  TextColumn get qualifications => text()();
  TextColumn get reason => text()();
  IntColumn get status => integer().withDefault(const Constant(0))();
  TextColumn get adminNote => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get reviewedAt => dateTime().nullable()();
}

class Departments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get code => text().unique()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class Semesters extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get year => integer()();
  IntColumn get term => integer()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
}

class AcademicCourses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get code => text().unique()();
  IntColumn get credits => integer().withDefault(const Constant(3))();
  IntColumn get departmentId => integer().references(Departments, #id)();
  TextColumn get description => text().nullable()();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get courseType => text().withDefault(const Constant('required'))();
  BoolColumn get isPublished => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

class CourseClasses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get academicCourseId =>
      integer().references(AcademicCourses, #id)();
  IntColumn get semesterId => integer().references(Semesters, #id)();
  IntColumn get teacherId => integer().nullable().references(Users, #id)();
  TextColumn get classCode => text().unique()();
  IntColumn get maxStudents => integer().withDefault(const Constant(50))();
  TextColumn get room => text().nullable()();
  TextColumn get schedule => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class CourseClassEnrollments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get courseClassId => integer().references(CourseClasses, #id)();
  @ReferenceName('enrollmentStudent')
  IntColumn get studentId => integer().references(Users, #id)();
  TextColumn get status => text().withDefault(const Constant('enrolled'))();
  TextColumn get source => text().withDefault(const Constant('import'))();
  RealColumn get progressPercent => real().withDefault(const Constant(0.0))();
  DateTimeColumn get enrolledAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class EnrollmentImports extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('importAdmin')
  IntColumn get adminId => integer().references(Users, #id)();
  IntColumn get semesterId => integer().references(Semesters, #id)();
  TextColumn get fileName => text()();
  IntColumn get totalRows => integer()();
  IntColumn get successCount => integer()();
  IntColumn get errorCount => integer()();
  TextColumn get errorDetails => text().nullable()();
  DateTimeColumn get importedAt => dateTime()();
}

class PersonalRoadmaps extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('personalRoadmapUser')
  IntColumn get userId => integer().references(Users, #id)();
  IntColumn get departmentId =>
      integer().nullable().references(Departments, #id)();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get isCustomized => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

class PersonalRoadmapItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get roadmapId => integer().references(PersonalRoadmaps, #id)();
  IntColumn get academicCourseId =>
      integer().references(AcademicCourses, #id)();
  IntColumn get semesterOrder => integer().withDefault(const Constant(1))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  BoolColumn get isRequired => boolean().withDefault(const Constant(true))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get addedAt => dateTime()();
}

@DriftDatabase(tables: [
  Users,
  StudentProfiles,
  Schedules,
  Classes,
  Subjects,
  Assignments,
  StudentAssignments,
  Notifications,
  Submissions,
  Attendances,
  Tasks,
  Quizzes,
  QuizQuestions,
  QuizAttempts,
  QuizStatistics,
  QuizRooms,
  RoomPlayers,
  Leaderboards,
  UserStreaks,
  Achievements,
  UserAchievements,
  QuizCache,
  Courses,
  Modules,
  Lessons,
  Enrollments,
  LessonProgress,
  CourseFiles,
  Comments,
  Roadmaps,
  RoadmapNodes,
  RoadmapEdges,
  StudentActivityLogs,
  CourseReviews,
  Majors,
  StudyPlans,
  ScheduledLessons,
  LearningActivities,
  CommentVotes,
  CommentMentions,
  ChatConversations,
  ChatMessages,
  TeacherApplications,
  Departments,
  Semesters,
  AcademicCourses,
  CourseClasses,
  CourseClassEnrollments,
  EnrollmentImports,
  PersonalRoadmaps,
  PersonalRoadmapItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_createDatabase());

  static QueryExecutor _createDatabase() {
    final env = DotEnv()..load();

    return PgDatabase(
      endpoint: Endpoint(
        host: env['DB_HOST'] ?? 'localhost',
        database: env['DB_NAME'] ?? 'alarmm_db',
        username: env['DB_USERNAME'] ?? 'postgres',
        password: env['DB_PASSWORD'] ?? '',
        port: int.tryParse(env['DB_PORT'] ?? '5432') ?? 5432,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
  }

  @override
  int get schemaVersion => 25;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        for (final table in allTables) {
          await m.createTable(table);
        }
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 3) {
          await m.drop(submissions);
          await m.drop(studentAssignments);
          await m.drop(attendances);
          await m.drop(assignments);
          await m.drop(schedules);
          await m.drop(classes);
          await m.drop(subjects);
          await m.drop(studentProfiles);
          await m.drop(tasks);
          await m.drop(notifications);
          await m.drop(users);

          for (final table in allTables) {
            await m.createTable(table);
          }
        }

        if (from < 4) {
          await m.addColumn(schedules, schedules.examScore);
        }

        if (from < 5) {
          await m.createTable(quizzes);
          await m.createTable(quizQuestions);
          await m.createTable(quizAttempts);
          await m.createTable(quizStatistics);
        }

        if (from < 6) {
          await m.createTable(quizRooms);
          await m.createTable(roomPlayers);
          await m.createTable(leaderboards);
          await m.createTable(userStreaks);
          await m.createTable(achievements);
          await m.createTable(userAchievements);
          await m.createTable(quizCache);
        }

        if (from < 7) {
          await m.createTable(courses);
          await m.createTable(modules);
          await m.createTable(lessons);
          await m.createTable(enrollments);
          await m.createTable(lessonProgress);
          await m.createTable(courseFiles);
        }

        if (from < 8) {
          await m.createTable(comments);
        }

        if (from < 9) {
          await m.createTable(roadmaps);
          await m.createTable(roadmapNodes);
          await m.createTable(roadmapEdges);
        }

        if (from < 10) {
          await m.createTable(studentActivityLogs);
          await m.createTable(courseReviews);
        }

        if (from < 11) {
          await m.addColumn(quizzes, quizzes.moduleId);
        }

        if (from < 12) {
          await m.addColumn(enrollments, enrollments.lastNudgedAt);
        }

        if (from < 13) {
          await m.createTable(majors);
          await m.addColumn(courses, courses.majorId);
        }

        if (from < 14) {
          await m.createTable(studyPlans);
          await m.createTable(scheduledLessons);
        }

        if (from < 15) {
          await m.createTable(learningActivities);
          await m.addColumn(comments, comments.upvotes);
          await m.addColumn(comments, comments.downvotes);
          await m.addColumn(comments, comments.isPinned);
          await m.addColumn(comments, comments.isAnswered);
          await m.addColumn(comments, comments.editedAt);
          await m.addColumn(comments, comments.depth);
          await m.addColumn(comments, comments.path);
          await m.createTable(commentVotes);
          await m.createTable(commentMentions);
        }

        if (from < 16) {
          await m.createTable(chatConversations);
          await m.createTable(chatMessages);
          await m.addColumn(submissions, submissions.autoGrade);
          await m.addColumn(submissions, submissions.autoGradeConfidence);
          await m.addColumn(submissions, submissions.rubricJson);
          await m.addColumn(courseReviews, courseReviews.teacherResponse);
          await m.addColumn(courseReviews, courseReviews.responseDate);
          await m.addColumn(courseReviews, courseReviews.helpfulCount);
        }

        if (from < 17) {
          await m.createTable(teacherApplications);
        }

        if (from < 18) {
          await m.createTable(departments);
          await m.createTable(semesters);
          await m.createTable(academicCourses);
          await m.createTable(courseClasses);
        }

        if (from < 19) {
          await m.addColumn(users, users.isBanned);
        }

        if (from < 20) {
          await m.issueCustomQuery(
              'DROP TABLE IF EXISTS course_class_enrollments CASCADE');
          await m.issueCustomQuery(
              'DROP TABLE IF EXISTS enrollment_imports CASCADE');
          await m
              .issueCustomQuery('DROP TABLE IF EXISTS course_classes CASCADE');
          await m.issueCustomQuery(
              'DROP TABLE IF EXISTS academic_courses CASCADE');

          await m.createTable(academicCourses);
          await m.createTable(courseClasses);
          await m.createTable(courseClassEnrollments);
          await m.createTable(enrollmentImports);

          await m.issueCustomQuery(
            'ALTER TABLE modules ADD COLUMN IF NOT EXISTS academic_course_id INTEGER REFERENCES academic_courses(id)',
          );
        }

        if (from < 21) {
          await m.issueCustomQuery(
            'ALTER TABLE modules ADD COLUMN IF NOT EXISTS course_id INTEGER REFERENCES courses(id)',
          );
        }

        if (from < 22) {
          await m.issueCustomQuery(
            'ALTER TABLE users ADD COLUMN IF NOT EXISTS department_id INTEGER REFERENCES departments(id)',
          );
          await m.issueCustomQuery(
            'ALTER TABLE student_profiles ADD COLUMN IF NOT EXISTS department_id INTEGER REFERENCES departments(id)',
          );
          await m.issueCustomQuery(
            'ALTER TABLE student_profiles ADD COLUMN IF NOT EXISTS student_class TEXT',
          );
        }

        if (from < 23) {
          await m.createTable(personalRoadmaps);
          await m.createTable(personalRoadmapItems);
        }

        if (from < 24) {
          await m.issueCustomQuery(
            'ALTER TABLE student_profiles ADD COLUMN IF NOT EXISTS academic_year TEXT',
          );
        }

        if (from < 25) {
          await m.issueCustomQuery(
            'ALTER TABLE course_classes ALTER COLUMN teacher_id DROP NOT NULL',
          );
        }
      },
    );
  }
}
