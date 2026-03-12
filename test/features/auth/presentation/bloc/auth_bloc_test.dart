import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alarmm/core/error/failures.dart';
import 'package:alarmm/features/auth/domain/entities/user_entity.dart';
import 'package:alarmm/features/auth/domain/usecases/login_usercase.dart';
import 'package:alarmm/features/auth/domain/usecases/signup_usecase.dart';
import 'package:alarmm/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:alarmm/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:alarmm/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:alarmm/features/auth/presentation/bloc/auth_event.dart';
import 'package:alarmm/features/auth/presentation/bloc/auth_state.dart';
import 'package:alarmm/injection_container.dart';

// ── Mocks ──
class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockSignUpUseCase extends Mock implements SignUpUseCase {}

class MockForgotPasswordUseCase extends Mock implements ForgotPasswordUseCase {}

class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}

void main() {
  late AuthBloc authBloc;
  late MockLoginUseCase mockLogin;
  late MockSignUpUseCase mockSignUp;
  late MockForgotPasswordUseCase mockForgotPassword;
  late MockResetPasswordUseCase mockResetPassword;

  setUp(() async {
    mockLogin = MockLoginUseCase();
    mockSignUp = MockSignUpUseCase();
    mockForgotPassword = MockForgotPasswordUseCase();
    mockResetPassword = MockResetPasswordUseCase();

    // Setup SharedPreferences for DI
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Reset and register GetIt
    if (sl.isRegistered<SharedPreferences>()) {
      sl.unregister<SharedPreferences>();
    }
    sl.registerSingleton<SharedPreferences>(prefs);

    authBloc = AuthBloc(
      loginUseCase: mockLogin,
      signUpUseCase: mockSignUp,
      forgotPasswordUseCase: mockForgotPassword,
      resetPasswordUseCase: mockResetPassword,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  test('initial state is AuthInitial', () {
    expect(authBloc.state, isA<AuthInitial>());
  });

  group('LoginRequested', () {
    const tUser = UserEntity(
      id: 1,
      email: 'test@example.com',
      fullName: 'Test User',
      role: 0,
      token: 'abc123',
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when login succeeds',
      build: () {
        when(
          () => mockLogin(any(), any()),
        ).thenAnswer((_) async => const Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        LoginRequested(email: 'test@example.com', password: '123456'),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when login fails',
      build: () {
        when(
          () => mockLogin(any(), any()),
        ).thenAnswer((_) async => Left(ServerFailure('Invalid credentials')));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        LoginRequested(email: 'test@example.com', password: 'wrong'),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );

    blocTest<AuthBloc, AuthState>(
      'saves user id to SharedPreferences on successful login',
      build: () {
        when(
          () => mockLogin(any(), any()),
        ).thenAnswer((_) async => const Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        LoginRequested(email: 'test@example.com', password: '123456'),
      ),
      verify: (_) async {
        final prefs = sl<SharedPreferences>();
        expect(prefs.getInt('current_user_id'), equals(1));
      },
    );
  });

  // ── Sign Up ──
  group('SignUpRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when signup succeeds',
      build: () {
        when(
          () => mockSignUp(any(), any()),
        ).thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        SignUpRequested(email: 'new@example.com', password: '123456'),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when signup fails',
      build: () {
        when(
          () => mockSignUp(any(), any()),
        ).thenAnswer((_) async => Left(ServerFailure('Email already exists')));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        SignUpRequested(email: 'existing@example.com', password: '123456'),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );
  });

  // ── Forgot Password ──
  group('ForgotPasswordRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when forgot password succeeds',
      build: () {
        when(
          () => mockForgotPassword(any()),
        ).thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) =>
          bloc.add(ForgotPasswordRequested(email: 'test@example.com')),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when forgot password fails',
      build: () {
        when(
          () => mockForgotPassword(any()),
        ).thenAnswer((_) async => Left(ServerFailure('Email not found')));
        return authBloc;
      },
      act: (bloc) =>
          bloc.add(ForgotPasswordRequested(email: 'unknown@example.com')),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );
  });

  // ── Logout ──
  group('LogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthInitial] when logout is requested',
      build: () => authBloc,
      act: (bloc) => bloc.add(LogoutRequested()),
      expect: () => [isA<AuthInitial>()],
    );

    blocTest<AuthBloc, AuthState>(
      'removes user id from SharedPreferences on logout',
      build: () => authBloc,
      seed: () =>
          AuthSuccess(const UserEntity(id: 1, email: 'test@example.com')),
      act: (bloc) => bloc.add(LogoutRequested()),
      verify: (_) async {
        final prefs = sl<SharedPreferences>();
        expect(prefs.getInt('current_user_id'), isNull);
      },
    );
  });
}
