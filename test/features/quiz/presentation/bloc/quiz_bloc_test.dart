import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:alarmm/core/error/failures.dart';
import 'package:alarmm/features/quiz/domain/entities/quiz_entity.dart';
import 'package:alarmm/features/quiz/domain/usecases/quiz_usecases.dart';
import 'package:alarmm/features/quiz/presentation/bloc/quiz_bloc.dart';
import 'package:alarmm/features/quiz/presentation/bloc/quiz_event.dart';
import 'package:alarmm/features/quiz/presentation/bloc/quiz_state.dart';

// ── Mocks ──
class MockGenerateQuizUseCase extends Mock implements GenerateQuizUseCase {}

class MockGenerateQuizFromImageUseCase extends Mock
    implements GenerateQuizFromImageUseCase {}

class MockGenerateAdaptiveQuizUseCase extends Mock
    implements GenerateAdaptiveQuizUseCase {}

class MockSaveQuizUseCase extends Mock implements SaveQuizUseCase {}

class MockGetQuizByIdUseCase extends Mock implements GetQuizByIdUseCase {}

class MockGetMyQuizzesUseCase extends Mock implements GetMyQuizzesUseCase {}

class MockSubmitQuizUseCase extends Mock implements SubmitQuizUseCase {}

class MockGetQuizStatisticsUseCase extends Mock
    implements GetQuizStatisticsUseCase {}

void main() {
  late QuizBloc quizBloc;
  late MockGenerateQuizUseCase mockGenerate;
  late MockGenerateQuizFromImageUseCase mockGenerateFromImage;
  late MockGenerateAdaptiveQuizUseCase mockGenerateAdaptive;
  late MockSaveQuizUseCase mockSave;
  late MockGetQuizByIdUseCase mockGetById;
  late MockGetMyQuizzesUseCase mockGetMyQuizzes;
  late MockSubmitQuizUseCase mockSubmit;
  late MockGetQuizStatisticsUseCase mockGetStats;

  const tQuestion = QuestionEntity(
    question: 'Flutter là gì?',
    options: ['Framework', 'Language', 'IDE', 'OS'],
    correctIndex: 0,
    explanation: 'Flutter là framework của Google',
  );

  const tQuiz = QuizEntity(
    id: 1,
    topic: 'Flutter Basics',
    difficulty: 'easy',
    questions: [tQuestion],
  );

  setUp(() {
    mockGenerate = MockGenerateQuizUseCase();
    mockGenerateFromImage = MockGenerateQuizFromImageUseCase();
    mockGenerateAdaptive = MockGenerateAdaptiveQuizUseCase();
    mockSave = MockSaveQuizUseCase();
    mockGetById = MockGetQuizByIdUseCase();
    mockGetMyQuizzes = MockGetMyQuizzesUseCase();
    mockSubmit = MockSubmitQuizUseCase();
    mockGetStats = MockGetQuizStatisticsUseCase();

    quizBloc = QuizBloc(
      generateQuiz: mockGenerate,
      generateQuizFromImage: mockGenerateFromImage,
      generateAdaptiveQuiz: mockGenerateAdaptive,
      saveQuiz: mockSave,
      getQuizById: mockGetById,
      getMyQuizzes: mockGetMyQuizzes,
      submitQuiz: mockSubmit,
      getStatistics: mockGetStats,
    );
  });

  tearDown(() => quizBloc.close());

  test('initial state is QuizInitial', () {
    expect(quizBloc.state, isA<QuizInitial>());
  });

  // ── Generate Quiz ──
  group('GenerateQuizEvent', () {
    blocTest<QuizBloc, QuizState>(
      'emits [Loading, Generated] when succeeds',
      build: () {
        when(
          () => mockGenerate(
            topic: any(named: 'topic'),
            numQuestions: any(named: 'numQuestions'),
            difficulty: any(named: 'difficulty'),
            subjectContext: any(named: 'subjectContext'),
            questionTypes: any(named: 'questionTypes'),
            videoUrl: any(named: 'videoUrl'),
          ),
        ).thenAnswer((_) async => const Right(tQuiz));
        return quizBloc;
      },
      act: (bloc) => bloc.add(
        const GenerateQuizEvent(
          topic: 'Flutter',
          numQuestions: 5,
          difficulty: 'easy',
        ),
      ),
      expect: () => [isA<QuizLoading>(), isA<QuizGenerated>()],
    );

    blocTest<QuizBloc, QuizState>(
      'emits [Loading, Error] when fails',
      build: () {
        when(
          () => mockGenerate(
            topic: any(named: 'topic'),
            numQuestions: any(named: 'numQuestions'),
            difficulty: any(named: 'difficulty'),
            subjectContext: any(named: 'subjectContext'),
            questionTypes: any(named: 'questionTypes'),
            videoUrl: any(named: 'videoUrl'),
          ),
        ).thenAnswer((_) async => Left(ServerFailure('API error')));
        return quizBloc;
      },
      act: (bloc) => bloc.add(
        const GenerateQuizEvent(
          topic: 'Flutter',
          numQuestions: 5,
          difficulty: 'easy',
        ),
      ),
      expect: () => [isA<QuizLoading>(), isA<QuizError>()],
    );
  });

  // ── Load My Quizzes ──
  group('LoadMyQuizzesEvent', () {
    blocTest<QuizBloc, QuizState>(
      'emits [Loading, MyQuizzesLoaded] when succeeds',
      build: () {
        when(
          () => mockGetMyQuizzes(any()),
        ).thenAnswer((_) async => const Right([tQuiz]));
        return quizBloc;
      },
      act: (bloc) => bloc.add(const LoadMyQuizzesEvent(userId: 1)),
      expect: () => [isA<QuizLoading>(), isA<MyQuizzesLoaded>()],
    );
  });

  // ── Load Quiz by ID ──
  group('LoadQuizEvent', () {
    blocTest<QuizBloc, QuizState>(
      'emits [Loading, Generated] when succeeds',
      build: () {
        when(
          () => mockGetById(any()),
        ).thenAnswer((_) async => const Right(tQuiz));
        return quizBloc;
      },
      act: (bloc) => bloc.add(const LoadQuizEvent(quizId: 1)),
      expect: () => [isA<QuizLoading>(), isA<QuizGenerated>()],
    );

    blocTest<QuizBloc, QuizState>(
      'emits [Loading, Error] when fails',
      build: () {
        when(
          () => mockGetById(any()),
        ).thenAnswer((_) async => Left(ServerFailure('Not found')));
        return quizBloc;
      },
      act: (bloc) => bloc.add(const LoadQuizEvent(quizId: 999)),
      expect: () => [isA<QuizLoading>(), isA<QuizError>()],
    );
  });

  // ── Reset Quiz ──
  group('ResetQuizEvent', () {
    blocTest<QuizBloc, QuizState>(
      'emits [QuizInitial]',
      build: () => quizBloc,
      act: (bloc) => bloc.add(const ResetQuizEvent()),
      expect: () => [isA<QuizInitial>()],
    );
  });
}
