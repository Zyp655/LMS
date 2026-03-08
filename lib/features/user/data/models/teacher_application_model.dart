class TeacherApplicationEntity {
  final int? id;
  final int? userId;
  final String fullName;
  final String expertise;
  final String experience;
  final String qualifications;
  final String reason;
  final int status;
  final String? statusText;
  final String? adminNote;
  final String? createdAt;
  final String? reviewedAt;
  final bool hasApplication;

  const TeacherApplicationEntity({
    this.id,
    this.userId,
    this.fullName = '',
    this.expertise = '',
    this.experience = '',
    this.qualifications = '',
    this.reason = '',
    this.status = 0,
    this.statusText,
    this.adminNote,
    this.createdAt,
    this.reviewedAt,
    this.hasApplication = false,
  });

  factory TeacherApplicationEntity.fromJson(Map<String, dynamic> json) {
    return TeacherApplicationEntity(
      id: json['id'] as int?,
      userId: json['userId'] as int?,
      fullName: json['fullName'] as String? ?? '',
      expertise: json['expertise'] as String? ?? '',
      experience: json['experience'] as String? ?? '',
      qualifications: json['qualifications'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: json['status'] as int? ?? 0,
      statusText: json['statusText'] as String?,
      adminNote: json['adminNote'] as String?,
      createdAt: json['createdAt'] as String?,
      reviewedAt: json['reviewedAt'] as String?,
      hasApplication: json['hasApplication'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'expertise': expertise,
    'experience': experience,
    'qualifications': qualifications,
    'reason': reason,
  };

  String get statusLabel {
    switch (status) {
      case 0:
        return 'Đang chờ duyệt';
      case 1:
        return 'Đã được duyệt';
      case 2:
        return 'Bị từ chối';
      default:
        return statusText ?? 'Không xác định';
    }
  }
}
