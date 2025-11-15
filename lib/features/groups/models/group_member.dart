class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String username;
  final String role; // 'owner' or 'member'
  final DateTime joinedAt;
  final int displayOrder;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.username,
    required this.role,
    required this.joinedAt,
    this.displayOrder = 0,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? 'Unknown',
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'username': username,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'display_order': displayOrder,
    };
  }

  bool get isOwner => role == 'owner';
  bool get isMember => role == 'member';
}
