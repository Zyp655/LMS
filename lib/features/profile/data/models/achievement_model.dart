import '../../domain/entities/achievement_entity.dart';

class AchievementModel extends AchievementEntity {
  const AchievementModel({
    required super.code,
    required super.name,
    required super.description,
    required super.iconName,
    required super.points,
    super.earned,
    super.earnedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconName: json['iconName'] ?? 'emoji_events',
      points: json['points'] ?? 0,
      earned: json['earned'] ?? false,
      earnedAt: json['earnedAt'] != null
          ? DateTime.tryParse(json['earnedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'description': description,
    'iconName': iconName,
    'points': points,
    'earned': earned,
    'earnedAt': earnedAt?.toIso8601String(),
  };
}
