import 'package:equatable/equatable.dart';

class AchievementEntity extends Equatable {
  final String code;
  final String name;
  final String description;
  final String iconName;
  final int points;
  final bool earned;
  final DateTime? earnedAt;

  const AchievementEntity({
    required this.code,
    required this.name,
    required this.description,
    required this.iconName,
    required this.points,
    this.earned = false,
    this.earnedAt,
  });

  @override
  List<Object?> get props => [
    code,
    name,
    description,
    iconName,
    points,
    earned,
    earnedAt,
  ];
}
