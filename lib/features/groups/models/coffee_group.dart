class CoffeeGroup {
  final String id;
  final String name;
  final String ownerId;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CoffeeGroup({
    required this.id,
    required this.name,
    required this.ownerId,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CoffeeGroup.fromJson(Map<String, dynamic> json) {
    return CoffeeGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CoffeeGroup copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CoffeeGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
