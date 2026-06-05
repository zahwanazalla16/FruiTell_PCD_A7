import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../models/ripeness_analysis_input.dart';
import '../models/ripeness_result.dart';
import '../models/fruit_database_model.dart';

/// Service untuk analyze ripeness dari input data
class RipenessAnalyzerService {
  /// Analyze ripeness berdasarkan input dan fruit characteristics dari database
  static RipenessResult analyzeRipeness({
    required RipenessAnalysisInput input,
    required FruitCharacteristics fruitChar,
    required List<RipenessLevelData> ripenessLevels,
  }) {
    // Menghitung ripeness score (dalam persenan 0-100) berdasarkan dataset Roboflow (gabungan)
    // Label YOLO dari dataset berisi label gabungan seperti "Apple Unripe", "Apple Ripe", "Apple Overripe".
    final String labelLower = input.fruitLabel.toLowerCase();
    final double confidence = input.confidence;
    
    double calculatedScore = 50.0; // Default
    String detectedLevelName = 'RIPE'; // Default

    if (labelLower.contains('unripe')) {
      // Unripe: Range 20% - 40% berdasarkan confidence model
      calculatedScore = 20.0 + (confidence * 20.0);
      detectedLevelName = 'UNRIPE';
    } else if (labelLower.contains('overripe')) {
      // Overripe: Range 85% - 100% berdasarkan confidence model
      calculatedScore = 85.0 + (confidence * 15.0);
      detectedLevelName = 'OVERRIPE';
    } else if (labelLower.contains('ripe')) {
      // Ripe: Range 50% - 90% berdasarkan confidence model
      calculatedScore = 50.0 + (confidence * 40.0);
      detectedLevelName = 'RIPE';
    } else {
      // Fallback jika label tidak mengandung ketiganya, hitung manual
      calculatedScore = confidence * 100.0;
      detectedLevelName = calculatedScore < 40
          ? 'UNRIPE'
          : (calculatedScore < 85 ? 'RIPE' : 'OVERRIPE');
    }

    final int ripenessScore = calculatedScore.round().clamp(0, 100);

    // Cari matching ripeness level dari database Supabase berdasarkan levelName
    final RipenessLevelData matchedLevel = ripenessLevels.firstWhere(
      (level) => level.levelName.toUpperCase() == detectedLevelName,
      orElse: () => ripenessLevels.firstWhere(
        (level) => ripenessScore >= level.scoreMin && ripenessScore <= level.scoreMax,
        orElse: () => ripenessLevels.last,
      ),
    );

    // Calculate best eat date
    final DateTime now = DateTime.now();
    final int daysToAdd = matchedLevel.daysToNextLevel;
    final DateTime bestEatDate = now.add(Duration(days: daysToAdd));
    final DateTime canEatUntil = bestEatDate.add(Duration(days: fruitChar.shelfLifeDays));

    // Format best eat range untuk display
    final String bestEatRange = _formatDateRange(bestEatDate, canEatUntil);

    // AI Confidence: combine YOLO confidence dengan score confidence
    final double aiConfidence = (input.confidence * (ripenessScore / 100)).clamp(0.0, 1.0);

    // Select top 2-3 preparation tips
    final List<String> selectedTips = _selectTopTips(matchedLevel.preparationTips, 3);

    return RipenessResult(
      ripenessLevel: matchedLevel.levelName,
      ripenessScore: ripenessScore,
      aiConfidence: aiConfidence,
      bestEatDate: bestEatDate,
      bestEatRange: bestEatRange,
      canEatUntil: canEatUntil,
      preparationTips: selectedTips,
      storageMethod: matchedLevel.storageRecommendation,
      fruitName: fruitChar.fruitName,
      nutritionInfo: fruitChar.nutritionInfo,
      daysUntilOptimal: daysToAdd,
    );
  }

  /// Select top N tips
  static List<String> _selectTopTips(List<String> tips, int maxTips) {
    return tips.take(maxTips).toList();
  }

  /// Format date range untuk display
  static String _formatDateRange(DateTime start, DateTime end) {
    final String startDay = _formatDay(start);
    final String endDay = _formatDay(end);

    // Jika same day
    if (start.day == end.day && start.month == end.month && start.year == end.year) {
      return 'Hari ini';
    }

    // Format: "5-14 Juni" atau "5 Juni - 14 Juli"
    if (start.month == end.month) {
      return '${start.day} - ${end.day} ${_getMonthName(start.month)}';
    } else {
      return '$startDay - $endDay';
    }
  }

  /// Format single date untuk display
  static String _formatDay(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)}';
  }

  /// Get bulan name in Indonesian
  static String _getMonthName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return monthNames[month - 1];
  }

  /// Calculate average luma dari image (untuk context)
  /// Bisa dipake langsung dari inference_service
  static double calculateAverageLuma(img.Image image) {
    double sum = 0;
    int pixelCount = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        // Luma = 0.299R + 0.587G + 0.114B
        final luma = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
        sum += luma;
        pixelCount++;
      }
    }

    return pixelCount > 0 ? sum / pixelCount : 0;
  }
}
