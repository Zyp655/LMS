import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class RoadmapRepository {
  Future<Either<Failure, Map<String, dynamic>>> getPersonalRoadmap(int userId);
  Future<Either<Failure, String>> resetRoadmap(int userId);
  Future<Either<Failure, String>> addItem({
    required int roadmapId,
    required int academicCourseId,
    int? semesterOrder,
  });
  Future<Either<Failure, String>> updateItem(Map<String, dynamic> data);
  Future<Either<Failure, String>> removeItem(int itemId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getSuggestions({
    required int departmentId,
    int? roadmapId,
  });
}
