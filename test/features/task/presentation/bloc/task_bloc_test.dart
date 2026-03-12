import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:alarmm/core/error/failures.dart';
import 'package:alarmm/features/task/domain/entities/task_entity.dart';
import 'package:alarmm/features/task/domain/usecases/get_tasks_usecase.dart';
import 'package:alarmm/features/task/domain/usecases/create_task_usecase.dart';
import 'package:alarmm/features/task/domain/usecases/update_task_usecase.dart';
import 'package:alarmm/features/task/domain/usecases/delete_task_usecase.dart';
import 'package:alarmm/features/task/presentation/bloc/task_bloc.dart';
import 'package:alarmm/features/task/presentation/bloc/task_event.dart';
import 'package:alarmm/features/task/presentation/bloc/task_state.dart';

// ── Mocks ──
class MockGetTasksUseCase extends Mock implements GetTasksUseCase {}

class MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}

class MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase {}

class MockDeleteTaskUseCase extends Mock implements DeleteTaskUseCase {}

// ── Fakes ──
class FakeTaskEntity extends Fake implements TaskEntity {}

void main() {
  late TaskBloc taskBloc;
  late MockGetTasksUseCase mockGetTasks;
  late MockCreateTaskUseCase mockCreateTask;
  late MockUpdateTaskUseCase mockUpdateTask;
  late MockDeleteTaskUseCase mockDeleteTask;

  final tTask = TaskEntity(
    id: 1,
    title: 'Test Task',
    description: 'Description',
    dueDate: DateTime(2026, 3, 1),
    isCompleted: false,
    userId: 1,
  );

  final tTaskList = [tTask];

  setUpAll(() {
    registerFallbackValue(FakeTaskEntity());
  });

  setUp(() {
    mockGetTasks = MockGetTasksUseCase();
    mockCreateTask = MockCreateTaskUseCase();
    mockUpdateTask = MockUpdateTaskUseCase();
    mockDeleteTask = MockDeleteTaskUseCase();
    taskBloc = TaskBloc(
      getTasks: mockGetTasks,
      createTask: mockCreateTask,
      updateTask: mockUpdateTask,
      deleteTask: mockDeleteTask,
    );
  });

  tearDown(() => taskBloc.close());

  test('initial state is TaskInitial', () {
    expect(taskBloc.state, isA<TaskInitial>());
  });

  // ── Load Tasks ──
  group('LoadTasks', () {
    blocTest<TaskBloc, TaskState>(
      'emits [TaskLoading, TaskLoaded] when loading succeeds',
      build: () {
        when(
          () => mockGetTasks(any()),
        ).thenAnswer((_) async => Right(tTaskList));
        return taskBloc;
      },
      act: (bloc) => bloc.add(const LoadTasks(1)),
      expect: () => [isA<TaskLoading>(), isA<TaskLoaded>()],
    );

    blocTest<TaskBloc, TaskState>(
      'emits [TaskLoading, TaskError] when loading fails',
      build: () {
        when(
          () => mockGetTasks(any()),
        ).thenAnswer((_) async => Left(ServerFailure('Server error')));
        return taskBloc;
      },
      act: (bloc) => bloc.add(const LoadTasks(1)),
      expect: () => [isA<TaskLoading>(), isA<TaskError>()],
    );
  });

  // ── Add Task ──
  group('AddTask', () {
    blocTest<TaskBloc, TaskState>(
      'emits [TaskLoading, TaskOperationSuccess, ...] then triggers reload on success',
      build: () {
        when(() => mockCreateTask(any())).thenAnswer((_) async => Right(tTask));
        when(
          () => mockGetTasks(any()),
        ).thenAnswer((_) async => Right(tTaskList));
        return taskBloc;
      },
      act: (bloc) => bloc.add(AddTask(tTask)),
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TaskLoading>(),
        isA<TaskOperationSuccess>(),
        isA<TaskLoading>(), // from reload via add(LoadTasks)
        isA<TaskLoaded>(),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'emits [TaskLoading, TaskError] when add fails',
      build: () {
        when(
          () => mockCreateTask(any()),
        ).thenAnswer((_) async => Left(ServerFailure('Create failed')));
        return taskBloc;
      },
      act: (bloc) => bloc.add(AddTask(tTask)),
      expect: () => [isA<TaskLoading>(), isA<TaskError>()],
    );
  });

  // ── Delete Task ──
  group('DeleteTask', () {
    blocTest<TaskBloc, TaskState>(
      'emits [TaskOperationSuccess, ...] then triggers reload on success',
      build: () {
        when(
          () => mockDeleteTask(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetTasks(any()),
        ).thenAnswer((_) async => Right(<TaskEntity>[]));
        return taskBloc;
      },
      act: (bloc) => bloc.add(const DeleteTask(1, 1)),
      wait: const Duration(milliseconds: 300),
      expect: () => [
        isA<TaskOperationSuccess>(),
        isA<TaskLoading>(), // from reload via add(LoadTasks)
        isA<TaskLoaded>(),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'emits [TaskError] when delete fails',
      build: () {
        when(
          () => mockDeleteTask(any()),
        ).thenAnswer((_) async => Left(ServerFailure('Delete failed')));
        return taskBloc;
      },
      act: (bloc) => bloc.add(const DeleteTask(1, 1)),
      expect: () => [isA<TaskError>()],
    );
  });
}
