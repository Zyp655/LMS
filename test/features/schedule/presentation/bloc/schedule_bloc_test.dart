import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:alarmm/core/error/failures.dart';
import 'package:alarmm/features/schedule/domain/enitities/schedule_entity.dart';
import 'package:alarmm/features/schedule/domain/usecases/get_schedules_usecase.dart';
import 'package:alarmm/features/schedule/domain/usecases/add_schedule_usecase.dart';
import 'package:alarmm/features/schedule/domain/usecases/delete_schedule_usecase.dart';
import 'package:alarmm/features/schedule/domain/usecases/update_schedule_usecase.dart';
import 'package:alarmm/features/schedule/domain/usecases/join_class_usecase.dart';
import 'package:alarmm/features/schedule/presentation/bloc/schedule_bloc.dart';
import 'package:alarmm/features/schedule/presentation/bloc/schedule_event.dart';
import 'package:alarmm/features/schedule/presentation/bloc/schedule_state.dart';

// ── Mocks ──
class MockGetSchedulesUseCase extends Mock implements GetSchedulesUseCase {}

class MockAddScheduleUseCase extends Mock implements AddScheduleUseCase {}

class MockDeleteScheduleUseCase extends Mock implements DeleteScheduleUseCase {}

class MockUpdateScheduleUseCase extends Mock implements UpdateScheduleUseCase {}

class MockJoinClassUseCase extends Mock implements JoinClassUseCase {}

// ── Fakes ──
class FakeScheduleEntity extends Fake implements ScheduleEntity {}

void main() {
  late ScheduleBloc scheduleBloc;
  late MockGetSchedulesUseCase mockGet;
  late MockAddScheduleUseCase mockAdd;
  late MockDeleteScheduleUseCase mockDelete;
  late MockUpdateScheduleUseCase mockUpdate;
  late MockJoinClassUseCase mockJoin;

  setUpAll(() {
    registerFallbackValue(FakeScheduleEntity());
    registerFallbackValue(<ScheduleEntity>[]);
  });

  setUp(() {
    mockGet = MockGetSchedulesUseCase();
    mockAdd = MockAddScheduleUseCase();
    mockDelete = MockDeleteScheduleUseCase();
    mockUpdate = MockUpdateScheduleUseCase();
    mockJoin = MockJoinClassUseCase();
    scheduleBloc = ScheduleBloc(
      getSchedulesUseCase: mockGet,
      addScheduleUseCase: mockAdd,
      deleteScheduleUseCase: mockDelete,
      updateScheduleUseCase: mockUpdate,
      joinClassUseCase: mockJoin,
    );
  });

  tearDown(() => scheduleBloc.close());

  test('initial state is ScheduleInitial', () {
    expect(scheduleBloc.state, isA<ScheduleInitial>());
  });

  // ── Load Schedules ──
  group('LoadSchedules', () {
    blocTest<ScheduleBloc, ScheduleState>(
      'emits [Loading, Error] when fails',
      build: () {
        when(
          () => mockGet(),
        ).thenAnswer((_) async => Left(ServerFailure('Server error')));
        return scheduleBloc;
      },
      act: (bloc) => bloc.add(LoadSchedules()),
      expect: () => [isA<ScheduleLoading>(), isA<ScheduleError>()],
    );
  });

  // ── Join Class ──
  group('JoinClassRequested', () {
    blocTest<ScheduleBloc, ScheduleState>(
      'emits [Loading, Error] when join fails',
      build: () {
        when(
          () => mockJoin(any()),
        ).thenAnswer((_) async => Left(ServerFailure('Invalid code')));
        return scheduleBloc;
      },
      act: (bloc) => bloc.add(JoinClassRequested('INVALID')),
      expect: () => [isA<ScheduleLoading>(), isA<ScheduleError>()],
    );
  });

  // ── Delete Schedule ──
  group('DeleteScheduleRequested', () {
    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleError] when delete fails',
      build: () {
        when(
          () => mockDelete(any()),
        ).thenAnswer((_) async => Left(ServerFailure('Delete error')));
        return scheduleBloc;
      },
      act: (bloc) => bloc.add(DeleteScheduleRequested(1)),
      expect: () => [isA<ScheduleError>()],
    );
  });

  // ── Update Schedule ──
  group('UpdateScheduleRequested', () {
    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleError] when update fails',
      build: () {
        when(
          () => mockUpdate(any()),
        ).thenAnswer((_) async => Left(ServerFailure('Update error')));
        return scheduleBloc;
      },
      act: (bloc) => bloc.add(
        UpdateScheduleRequested(
          ScheduleEntity(
            id: 1,
            subject: 'Test',
            room: 'A1',
            start: DateTime(2026, 3, 1),
            end: DateTime(2026, 3, 1),
          ),
        ),
      ),
      expect: () => [isA<ScheduleError>()],
    );
  });

  // ── Reset ──
  group('ResetSchedule', () {
    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleInitial]',
      build: () => scheduleBloc,
      act: (bloc) => bloc.add(ResetSchedule()),
      expect: () => [isA<ScheduleInitial>()],
    );
  });

  // ── Add Schedule ──
  group('AddScheduleRequested', () {
    blocTest<ScheduleBloc, ScheduleState>(
      'emits [ScheduleError] when add fails',
      build: () {
        when(
          () => mockAdd(any()),
        ).thenAnswer((_) async => Left(ServerFailure('Add error')));
        return scheduleBloc;
      },
      act: (bloc) => bloc.add(
        AddScheduleRequested(
          ScheduleEntity(
            id: 1,
            subject: 'Test',
            room: 'A1',
            start: DateTime(2026, 3, 1),
            end: DateTime(2026, 3, 1),
          ),
        ),
      ),
      expect: () => [isA<ScheduleError>()],
    );
  });
}
