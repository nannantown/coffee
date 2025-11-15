class EspressoRecipe {
  final String id;
  final String groupId;
  final String createdBy;
  final String createdByUsername;
  final String? createdByAvatarUrl;
  final String updatedBy;
  final String updatedByUsername;
  final String? sourceShotId;
  final double coffeeWeight;
  final String grinderSetting;
  final int? extractionTime;
  final double? roastLevel;
  final int rating;
  final String extractionSpeed;
  final String? notes;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EspressoRecipe({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.createdByUsername,
    this.createdByAvatarUrl,
    required this.updatedBy,
    required this.updatedByUsername,
    this.sourceShotId,
    required this.coffeeWeight,
    required this.grinderSetting,
    this.extractionTime,
    this.roastLevel,
    required this.rating,
    required this.extractionSpeed,
    this.notes,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EspressoRecipe.fromJson(Map<String, dynamic> json) {
    return EspressoRecipe(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      createdBy: json['created_by'] as String,
      createdByUsername: json['created_by_username'] as String? ?? 'Unknown',
      createdByAvatarUrl: json['created_by_avatar_url'] as String?,
      updatedBy: json['updated_by'] as String,
      updatedByUsername: json['updated_by_username'] as String? ?? 'Unknown',
      sourceShotId: json['source_shot_id'] as String?,
      coffeeWeight: (json['coffee_weight'] as num).toDouble(),
      grinderSetting: json['grinder_setting'] as String,
      extractionTime: json['extraction_time'] as int?,
      roastLevel: json['roast_level'] != null
          ? (json['roast_level'] as num).toDouble()
          : null,
      rating: json['rating'] as int? ?? 3,
      extractionSpeed: json['extraction_speed'] as String? ?? 'optimal',
      notes: json['notes'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'source_shot_id': sourceShotId,
      'coffee_weight': coffeeWeight,
      'grinder_setting': grinderSetting,
      'extraction_time': extractionTime,
      'roast_level': roastLevel,
      'rating': rating,
      'extraction_speed': extractionSpeed,
      'notes': notes,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  EspressoRecipe copyWith({
    String? id,
    String? groupId,
    String? createdBy,
    String? createdByUsername,
    String? createdByAvatarUrl,
    String? updatedBy,
    String? updatedByUsername,
    String? sourceShotId,
    double? coffeeWeight,
    String? grinderSetting,
    int? extractionTime,
    double? roastLevel,
    int? rating,
    String? extractionSpeed,
    String? notes,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EspressoRecipe(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      createdBy: createdBy ?? this.createdBy,
      createdByUsername: createdByUsername ?? this.createdByUsername,
      createdByAvatarUrl: createdByAvatarUrl ?? this.createdByAvatarUrl,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByUsername: updatedByUsername ?? this.updatedByUsername,
      sourceShotId: sourceShotId ?? this.sourceShotId,
      coffeeWeight: coffeeWeight ?? this.coffeeWeight,
      grinderSetting: grinderSetting ?? this.grinderSetting,
      extractionTime: extractionTime ?? this.extractionTime,
      roastLevel: roastLevel ?? this.roastLevel,
      rating: rating ?? this.rating,
      extractionSpeed: extractionSpeed ?? this.extractionSpeed,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
