import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/roadmap_repository.dart';

class GetPersonalRoadmapUseCase {
  final RoadmapRepository repository;
  GetPersonalRoadmapUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(int userId) {
    return repository.getPersonalRoadmap(userId);
  }
}

class ResetRoadmapUseCase {
  final RoadmapRepository repository;
  ResetRoadmapUseCase(this.repository);

  Future<Either<Failure, String>> call(int userId) {
    return repository.resetRoadmap(userId);
  }
}

class AddRoadmapItemUseCase {
  final RoadmapRepository repository;
  AddRoadmapItemUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required int roadmapId,
    required int academicCourseId,
    int? semesterOrder,
  }) {
    return repository.addItem(
      roadmapId: roadmapId,
      academicCourseId: academicCourseId,
      semesterOrder: semesterOrder,
    );
  }
}

class UpdateRoadmapItemUseCase {
  final RoadmapRepository repository;
  UpdateRoadmapItemUseCase(this.repository);

  Future<Either<Failure, String>> call(Map<String, dynamic> data) {
    return repository.updateItem(data);
  }
}

class RemoveRoadmapItemUseCase {
  final RoadmapRepository repository;
  RemoveRoadmapItemUseCase(this.repository);

  Future<Either<Failure, String>> call(int itemId) {
    return repository.removeItem(itemId);
  }
}

class GetRoadmapSuggestionsUseCase {
  final RoadmapRepository repository;
  GetRoadmapSuggestionsUseCase(this.repository);

  Future<Either<Failure, List<Map<String, dynamic>>>> call({
    required int departmentId,
    int? roadmapId,
  }) {
    return repository.getSuggestions(
      departmentId: departmentId,
      roadmapId: roadmapId,
    );
  }
}
