class EspressoRecipe {
  final String id;
  final String groupId;
  final String createdBy;
  final String createdByUsername;
  final double coffeeWeight;
  final String grinderSetting;
  final int? extractionTime;
  final double? roastLevel;
  final int rating;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EspressoRecipe({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.createdByUsername,
    required this.coffeeWeight,
    required this.grinderSetting,
    this.extractionTime,
    this.roastLevel,
    required this.rating,
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
      coffeeWeight: (json['coffee_weight'] as num).toDouble(),
      grinderSetting: json['grinder_setting'] as String,
      extractionTime: json['extraction_time'] as int?,
      roastLevel: json['roast_level'] != null
          ? (json['roast_level'] as num).toDouble()
          : null,
      rating: json['rating'] as int,
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
      'coffee_weight': coffeeWeight,
      'grinder_setting': grinderSetting,
      'extraction_time': extractionTime,
      'roast_level': roastLevel,
      'rating': rating,
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
    double? coffeeWeight,
    String? grinderSetting,
    int? extractionTime,
    double? roastLevel,
    int? rating,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EspressoRecipe(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      createdBy: createdBy ?? this.createdBy,
      createdByUsername: createdByUsername ?? this.createdByUsername,
      coffeeWeight: coffeeWeight ?? this.coffeeWeight,
      grinderSetting: grinderSetting ?? this.grinderSetting,
      extractionTime: extractionTime ?? this.extractionTime,
      roastLevel: roastLevel ?? this.roastLevel,
      rating: rating ?? this.rating,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
