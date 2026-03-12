class LearningPath {
  final String id;
  final String title;
  final String description;
  final String gradientStart;
  final String gradientEnd;
  final List<LearningMilestone> milestones;

  const LearningPath({
    required this.id,
    required this.title,
    required this.description,
    required this.gradientStart,
    required this.gradientEnd,
    required this.milestones,
  });

  factory LearningPath.fromJson(Map<String, dynamic> json) {
    return LearningPath(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      gradientStart: json['gradientStart'] as String? ?? '#14B8A6',
      gradientEnd: json['gradientEnd'] as String? ?? '#06B6D4',
      milestones:
          (json['milestones'] as List<dynamic>?)
              ?.map(
                (m) => LearningMilestone.fromJson(m as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'gradientStart': gradientStart,
    'gradientEnd': gradientEnd,
    'milestones': milestones.map((m) => m.toJson()).toList(),
  };
}

class LearningMilestone {
  final String title;
  final List<LearningStep> steps;

  const LearningMilestone({required this.title, required this.steps});

  factory LearningMilestone.fromJson(Map<String, dynamic> json) {
    return LearningMilestone(
      title: json['title'] as String? ?? '',
      steps:
          (json['steps'] as List<dynamic>?)
              ?.map((s) => LearningStep.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'steps': steps.map((s) => s.toJson()).toList(),
  };
}

class LearningStep {
  final String title;
  final String type;

  const LearningStep({required this.title, required this.type});

  factory LearningStep.fromJson(Map<String, dynamic> json) {
    return LearningStep(
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'lesson',
    );
  }

  Map<String, dynamic> toJson() => {'title': title, 'type': type};
}
