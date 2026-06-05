/// Karakteristik buah dari Supabase
class FruitCharacteristics {
  FruitCharacteristics({
    required this.fruitName,
    required this.shelfLifeDays,
    this.colorRipeHMin = 0,
    this.colorRipeHMax = 360,
    this.colorRipeSMin = 0,
    this.colorRipeSMax = 100,
    this.textureSmoothMin = 0,
    this.textureSmoothMax = 100,
    this.sizeMinGram = 0,
    this.sizeMaxGram = 10000,
    this.preparationTips = const [],
    this.nutritionInfo = '',
  });

  final String fruitName;
  final int shelfLifeDays;
  final int colorRipeHMin;
  final int colorRipeHMax;
  final int colorRipeSMin;
  final int colorRipeSMax;
  final int textureSmoothMin;
  final int textureSmoothMax;
  final int sizeMinGram;
  final int sizeMaxGram;
  final List<String> preparationTips;
  final String nutritionInfo;

  /// Factory untuk create dari JSON (Supabase response)
  factory FruitCharacteristics.fromJson(Map<String, dynamic> json) {
    return FruitCharacteristics(
      fruitName: json['fruit_name'] ?? '',
      shelfLifeDays: json['shelf_life_days'] ?? 7,
      colorRipeHMin: json['color_range_ripe_h_min'] ?? 0,
      colorRipeHMax: json['color_range_ripe_h_max'] ?? 360,
      colorRipeSMin: json['color_range_ripe_s_min'] ?? 0,
      colorRipeSMax: json['color_range_ripe_s_max'] ?? 100,
      textureSmoothMin: json['texture_smoothness_min'] ?? 0,
      textureSmoothMax: json['texture_smoothness_max'] ?? 100,
      sizeMinGram: json['size_min_gram'] ?? 0,
      sizeMaxGram: json['size_max_gram'] ?? 10000,
      preparationTips: List<String>.from(json['preparation_tips'] ?? []),
      nutritionInfo: json['nutrition_info'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'fruit_name': fruitName,
        'shelf_life_days': shelfLifeDays,
        'color_range_ripe_h_min': colorRipeHMin,
        'color_range_ripe_h_max': colorRipeHMax,
        'color_range_ripe_s_min': colorRipeSMin,
        'color_range_ripe_s_max': colorRipeSMax,
        'texture_smoothness_min': textureSmoothMin,
        'texture_smoothness_max': textureSmoothMax,
        'size_min_gram': sizeMinGram,
        'size_max_gram': sizeMaxGram,
        'preparation_tips': preparationTips,
        'nutrition_info': nutritionInfo,
      };
}

/// Ripeness level untuk setiap buah
/// 3 levels sesuai dataset Roboflow: UNRIPE, RIPE, OVERRIPE
class RipenessLevelData {
  RipenessLevelData({
    required this.levelName, // "UNRIPE", "RIPE", "OVERRIPE"
    required this.scoreMin,
    required this.scoreMax,
    required this.preparationTips,
    required this.bestEatenIn,
    required this.storageRecommendation,
    this.daysToNextLevel = 0, // Untuk hitung best eat date
  });

  final String levelName;
  final int scoreMin;
  final int scoreMax;
  final List<String> preparationTips;
  final String bestEatenIn; // "1-2 hari", "hari ini", etc
  final String storageRecommendation;
  final int daysToNextLevel;

  /// Factory dari JSON (Supabase response)
  factory RipenessLevelData.fromJson(Map<String, dynamic> json) {
    return RipenessLevelData(
      levelName: json['level_name'] ?? 'UNKNOWN',
      scoreMin: json['ripeness_score_min'] ?? 0,
      scoreMax: json['ripeness_score_max'] ?? 100,
      preparationTips: List<String>.from(json['preparation_tips'] ?? []),
      bestEatenIn: json['best_eaten_in'] ?? 'Tidak diketahui',
      storageRecommendation: json['storage_recommendation'] ?? 'Suhu ruangan',
      daysToNextLevel: json['days_to_next_level'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'level_name': levelName,
        'ripeness_score_min': scoreMin,
        'ripeness_score_max': scoreMax,
        'preparation_tips': preparationTips,
        'best_eaten_in': bestEatenIn,
        'storage_recommendation': storageRecommendation,
        'days_to_next_level': daysToNextLevel,
      };
}
