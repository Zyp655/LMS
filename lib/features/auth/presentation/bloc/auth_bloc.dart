import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../injection_container.dart';
import '../../../../core/api/api_client.dart';

import '../../../../features/schedule/presentation/bloc/schedule_bloc.dart';
import '../../../../features/schedule/presentation/bloc/schedule_event.dart';
import '../../domain/usecases/login_usercase.dart';
import '../../domain/usecases/signup_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../data/models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../../core/services/fcm_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final SignUpUseCase signUpUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.signUpUseCase,
    required this.forgotPasswordUseCase,
    required this.resetPasswordUseCase,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<SignUpRequested>(_onSignUp);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<ResetPasswordRequested>(_onResetPassword);
    on<LogoutRequested>(_onLogout);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final prefs = sl<SharedPreferences>();
    final token = prefs.getString('token');
    final userId = prefs.getInt('userId') ?? prefs.getInt('current_user_id');

    if (token == null || userId == null) {
      emit(AuthInitial());
      return;
    }

    try {
      final apiClient = sl<ApiClient>();
      final response = await apiClient.get('/users/$userId');
      final user = UserModel.fromJson({
        ...response as Map<String, dynamic>,
        'token': token,
      });
      await prefs.setInt('current_user_id', user.id);
      emit(AuthSuccess(user));
    } catch (_) {
      await prefs.remove('token');
      await prefs.remove('userId');
      await prefs.remove('current_user_id');
      emit(AuthInitial());
    }
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await loginUseCase(event.email, event.password);

    await result.fold((failure) async => emit(AuthFailure(failure)), (
      user,
    ) async {
      await sl<SharedPreferences>().setInt('current_user_id', user.id);
      FcmService().init(userId: user.id);
      emit(AuthSuccess(user));
    });
  }

  Future<void> _onSignUp(SignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await signUpUseCase(event.email, event.password);
    result.fold(
      (failure) => emit(AuthFailure(failure)),
      (_) => emit(AuthSuccess(null)),
    );
  }

  Future<void> _onForgotPassword(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await forgotPasswordUseCase(event.email);
    result.fold(
      (failure) => emit(AuthFailure(failure)),
      (_) => emit(OtpSentSuccess()),
    );
  }

  Future<void> _onResetPassword(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await resetPasswordUseCase(
      event.email,
      event.otp,
      event.newPassword,
    );
    result.fold(
      (failure) => emit(AuthFailure(failure)),
      (_) => emit(PasswordResetSuccess()),
    );
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    await sl<SharedPreferences>().remove('current_user_id');
    await sl<SharedPreferences>().remove('token');
    await sl<SharedPreferences>().remove('userId');
    try {
      if (sl.isRegistered<ScheduleBloc>()) {
        sl<ScheduleBloc>().add(ResetSchedule());
      }
    } catch (e) {}
    emit(AuthInitial());
  }
}

