import 'package:equatable/equatable.dart';

class LeaderboardEntry extends Equatable {
  final int rank;
  final int userId;
  final String name;
  final double totalScore;
  final int quizzesCompleted;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.totalScore,
    required this.quizzesCompleted,
  });

  @override
  List<Object?> get props => [rank, userId, name, totalScore, quizzesCompleted];

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      userId: json['userId'] as int,
      name: json['name'] as String,
      totalScore: (json['totalScore'] as num).toDouble(),
      quizzesCompleted: json['quizzesCompleted'] as int,
    );
  }
}
