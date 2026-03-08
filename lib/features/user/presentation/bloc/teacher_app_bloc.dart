import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/teacher_application_remote_data_source.dart';
import '../../data/models/teacher_application_model.dart';

abstract class TeacherAppEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadMyApplicationEvent extends TeacherAppEvent {}

class SubmitApplicationEvent extends TeacherAppEvent {
  final TeacherApplicationEntity application;
  SubmitApplicationEvent(this.application);
  @override
  List<Object?> get props => [application];
}

class LoadAllApplicationsEvent extends TeacherAppEvent {
  final int? statusFilter;
  LoadAllApplicationsEvent({this.statusFilter});
  @override
  List<Object?> get props => [statusFilter];
}

class ReviewApplicationEvent extends TeacherAppEvent {
  final int applicationId;
  final int status;
  final String? adminNote;
  ReviewApplicationEvent({
    required this.applicationId,
    required this.status,
    this.adminNote,
  });
  @override
  List<Object?> get props => [applicationId, status, adminNote];
}

abstract class TeacherAppState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TeacherAppInitial extends TeacherAppState {}

class TeacherAppLoading extends TeacherAppState {}

class MyApplicationLoaded extends TeacherAppState {
  final TeacherApplicationEntity application;
  MyApplicationLoaded(this.application);
  @override
  List<Object?> get props => [application];
}

class ApplicationSubmitted extends TeacherAppState {
  final String message;
  ApplicationSubmitted(this.message);
  @override
  List<Object?> get props => [message];
}

class AllApplicationsLoaded extends TeacherAppState {
  final List<TeacherApplicationEntity> applications;
  AllApplicationsLoaded(this.applications);
  @override
  List<Object?> get props => [applications];
}

class ApplicationReviewed extends TeacherAppState {
  final String message;
  ApplicationReviewed(this.message);
  @override
  List<Object?> get props => [message];
}

class TeacherAppError extends TeacherAppState {
  final String message;
  TeacherAppError(this.message);
  @override
  List<Object?> get props => [message];
}

class TeacherAppBloc extends Bloc<TeacherAppEvent, TeacherAppState> {
  final TeacherApplicationRemoteDataSource dataSource;

  TeacherAppBloc({required this.dataSource}) : super(TeacherAppInitial()) {
    on<LoadMyApplicationEvent>(_onLoadMyApplication);
    on<SubmitApplicationEvent>(_onSubmitApplication);
    on<LoadAllApplicationsEvent>(_onLoadAllApplications);
    on<ReviewApplicationEvent>(_onReviewApplication);
  }

  Future<void> _onLoadMyApplication(
    LoadMyApplicationEvent event,
    Emitter<TeacherAppState> emit,
  ) async {
    emit(TeacherAppLoading());
    try {
      final app = await dataSource.getMyApplication();
      emit(MyApplicationLoaded(app));
    } catch (e) {
      emit(TeacherAppError(e.toString()));
    }
  }

  Future<void> _onSubmitApplication(
    SubmitApplicationEvent event,
    Emitter<TeacherAppState> emit,
  ) async {
    emit(TeacherAppLoading());
    try {
      final result = await dataSource.submitApplication(event.application);
      emit(
        ApplicationSubmitted(result['message'] ?? 'Đơn đăng ký đã được gửi'),
      );
    } catch (e) {
      emit(TeacherAppError(e.toString()));
    }
  }

  Future<void> _onLoadAllApplications(
    LoadAllApplicationsEvent event,
    Emitter<TeacherAppState> emit,
  ) async {
    emit(TeacherAppLoading());
    try {
      final apps = await dataSource.getAllApplications(
        status: event.statusFilter,
      );
      emit(AllApplicationsLoaded(apps));
    } catch (e) {
      emit(TeacherAppError(e.toString()));
    }
  }

  Future<void> _onReviewApplication(
    ReviewApplicationEvent event,
    Emitter<TeacherAppState> emit,
  ) async {
    emit(TeacherAppLoading());
    try {
      final result = await dataSource.reviewApplication(
        applicationId: event.applicationId,
        status: event.status,
        adminNote: event.adminNote,
      );
      emit(ApplicationReviewed(result['message'] ?? 'Đã xử lý'));
    } catch (e) {
      emit(TeacherAppError(e.toString()));
    }
  }
}
