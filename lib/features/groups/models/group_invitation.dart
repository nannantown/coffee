class GroupInvitation {
  final String id;
  final String groupId;
  final String inviteCode;
  final String createdBy;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const GroupInvitation({
    required this.id,
    required this.groupId,
    required this.inviteCode,
    required this.createdBy,
    this.expiresAt,
    required this.createdAt,
  });

  factory GroupInvitation.fromJson(Map<String, dynamic> json) {
    return GroupInvitation(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      inviteCode: json['invite_code'] as String,
      createdBy: json['created_by'] as String,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'invite_code': inviteCode,
      'created_by': createdBy,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}
