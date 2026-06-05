/// Output hasil analisis ripeness
class RipenessResult {
  RipenessResult({
    required this.ripenessLevel, // "UNRIPE" | "RIPE" | "OVERRIPE"
    required this.ripenessScore, // 0-100
    required this.aiConfidence, // 0.0-1.0 (confidence AI dalam analisis)
    required this.bestEatDate, // Kapan sebaiknya dimakan
    required this.bestEatRange, // Display text: "7-14 Juni"
    required this.canEatUntil, // Deadline untuk dimakan
    required this.preparationTips, // List of tips
    required this.storageMethod, // "Refrigerator" | "Room Temperature"
    required this.fruitName, // Normalized fruit name
    this.nutritionInfo = '',
    this.daysUntilOptimal = 0,
  });

  final String ripenessLevel;
  final int ripenessScore;
  final double aiConfidence;
  final DateTime bestEatDate;
  final String bestEatRange; // Display format: "5-14 Juni"
  final DateTime canEatUntil;
  final List<String> preparationTips;
  final String storageMethod;
  final String fruitName;
  final String nutritionInfo;
  final int daysUntilOptimal; // Untuk UNRIPE: berapa hari lagi

  /// Color indicator untuk UI
  String get levelColor {
    switch (ripenessLevel) {
      case 'UNRIPE':
        return '#FFD700'; // Gold
      case 'RIPE':
        return '#00C853'; // Green
      case 'OVERRIPE':
        return '#D50000'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  /// Emoji untuk display
  String get levelEmoji {
    switch (ripenessLevel) {
      case 'UNRIPE':
        return '😐';
      case 'RIPE':
        return '😋';
      case 'OVERRIPE':
        return '⚠️';
      default:
        return '❓';
    }
  }

  /// Indonesian translation untuk level
  String get levelIndonesian {
    switch (ripenessLevel) {
      case 'UNRIPE':
        return 'Mentah';
      case 'RIPE':
        return 'Matang';
      case 'OVERRIPE':
        return 'Terlalu Matang';
      default:
        return 'Tidak Diketahui';
    }
  }

  @override
  String toString() => '''
RipenessResult(
  level: $ripenessLevel ($ripenessScore%),
  confidence: $aiConfidence,
  bestEat: ${bestEatDate.toString().split(' ')[0]},
  storage: $storageMethod
)''';
}
