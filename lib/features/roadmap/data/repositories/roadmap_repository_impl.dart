import 'package:dartz/dartz.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/roadmap_repository.dart';

class RoadmapRepositoryImpl implements RoadmapRepository {
  final ApiClient apiClient;

  RoadmapRepositoryImpl({required this.apiClient});

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPersonalRoadmap(
    int userId,
  ) async {
    try {
      final response = await apiClient.get('/personal-roadmap?userId=$userId');
      return Right(response);
    } catch (e) {
      return Left(ServerFailure('Lỗi tải lộ trình: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> resetRoadmap(int userId) async {
    try {
      final response = await apiClient.post('/personal-roadmap', {
        'userId': userId,
      });
      return Right(response['message'] as String? ?? 'Đã tạo lại lộ trình');
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> addItem({
    required int roadmapId,
    required int academicCourseId,
    int? semesterOrder,
  }) async {
    try {
      final body = <String, dynamic>{
        'roadmapId': roadmapId,
        'academicCourseId': academicCourseId,
      };
      if (semesterOrder != null) body['semesterOrder'] = semesterOrder;
      final response = await apiClient.post('/personal-roadmap/items', body);
      return Right(response['message'] as String? ?? 'Đã thêm môn học');
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> updateItem(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.put('/personal-roadmap/items', data);
      return Right(response['message'] as String? ?? 'Cập nhật thành công');
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> removeItem(int itemId) async {
    try {
      final response = await apiClient.delete(
        '/personal-roadmap/items?itemId=$itemId',
      );
      return Right(response['message'] as String? ?? 'Đã xóa');
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getSuggestions({
    required int departmentId,
    int? roadmapId,
  }) async {
    try {
      var path = '/personal-roadmap/suggest?departmentId=$departmentId';
      if (roadmapId != null) path += '&roadmapId=$roadmapId';
      final response = await apiClient.get(path);
      final suggestions = List<Map<String, dynamic>>.from(
        response['suggestions'] ?? [],
      );
      return Right(suggestions);
    } catch (e) {
      return Left(ServerFailure('Lỗi: $e'));
    }
  }
}
