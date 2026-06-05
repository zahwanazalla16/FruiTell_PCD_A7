class DetectionResult {
  DetectionResult({
    required this.label,
    required this.confidence,
    required this.ripeness,
    required this.freshness,
    required this.bestBefore,
    required this.tips,
    // New fields untuk AI Ripeness Advisor
    this.ripenessLevel, // "UNRIPE", "RIPE", "OVERRIPE"
    this.ripenessScore, // 0-100
    this.aiConfidence, // 0.0-1.0
    this.bestEatDate,
    this.bestEatRange, // "5-14 Juni"
    this.storageMethod,
    this.fruitName, // normalized name
  });

  final String label;
  final double confidence;
  final String ripeness;
  final String freshness;
  final String bestBefore;
  final List<String> tips;
  
  // New AI Ripeness fields
  final String? ripenessLevel;
  final int? ripenessScore;
  final double? aiConfidence;
  final DateTime? bestEatDate;
  final String? bestEatRange;
  final String? storageMethod;
  final String? fruitName;

  /// Apakah sudah ada ripeness data dari AI?
  bool get hasRipenessData => ripenessLevel != null && bestEatRange != null;
}
