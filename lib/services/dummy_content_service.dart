import '../models/detection_result.dart';

class DummyContentService {
  static DetectionResult enrich(String label, double confidence) {
    final ripeness = _ripenessFromConfidence(confidence);
    final freshness = _freshnessFromConfidence(confidence);
    final fruitName = _fruitNameFromLabel(label);

    return DetectionResult(
      label: label,
      confidence: confidence,
      ripeness: ripeness,
      freshness: freshness,
      bestBefore: _bestBeforeFromRipeness(ripeness),
      tips: _tipsByFruit[fruitName] ?? _defaultTips,
    );
  }

  static String _ripenessFromConfidence(double confidence) {
    if (confidence >= 0.85) return 'Matang';
    if (confidence >= 0.65) return 'Setengah Matang';
    return 'Perlu Dicek Lagi';
  }

  static String _freshnessFromConfidence(double confidence) {
    final percent = (confidence * 100).clamp(1, 99).round();
    return '$percent% Fresh';
  }

  static String _bestBeforeFromRipeness(String ripeness) {
    switch (ripeness) {
      case 'Matang':
        return '2-4 Hari Lagi';
      case 'Setengah Matang':
        return '4-6 Hari Lagi';
      default:
        return 'Pantau Setiap Hari';
    }
  }

  static String _fruitNameFromLabel(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('apple')) return 'apple';
    if (normalized.contains('banana')) return 'banana';
    if (normalized.contains('mango')) return 'mango';
    if (normalized.contains('orange')) return 'orange';
    if (normalized.contains('papaya')) return 'papaya';
    if (normalized.contains('strawberry')) return 'strawberry';
    if (normalized.contains('dragon')) return 'dragon fruit';
    return 'fruit';
  }

  static const List<String> _defaultTips = [
    'Simpan di tempat sejuk dan kering.',
    'Hindari ditumpuk agar kulit tidak mudah memar.',
  ];

  static const Map<String, List<String>> _tipsByFruit = {
    'banana': [
      'Simpan pisang terpisah dari buah lain agar tidak cepat matang.',
      'Hindari kulkas saat masih hijau, simpan suhu ruang.',
    ],
    'apple': [
      'Simpan di kulkas untuk menjaga kerenyahan lebih lama.',
      'Jauhkan dari buah yang cepat matang seperti pisang.',
    ],
    'mango': [
      'Jika sudah matang, simpan di kulkas agar tahan 2-4 hari.',
      'Jangan ditumpuk untuk mencegah memar pada kulit.',
    ],
    'orange': [
      'Simpan di wadah berlubang agar sirkulasi udara baik.',
      'Jauhkan dari area lembap berlebih.',
    ],
    'papaya': [
      'Simpan suhu ruang sampai matang, lalu pindah ke kulkas.',
      'Potong seperlunya lalu simpan di wadah tertutup.',
    ],
    'strawberry': [
      'Simpan dalam wadah berlapis tisu untuk menyerap lembap.',
      'Cuci hanya sebelum dimakan agar tidak cepat busuk.',
    ],
    'dragon fruit': [
      'Simpan di suhu ruang bila belum matang sempurna.',
      'Setelah matang, simpan di kulkas agar tekstur tetap segar.',
    ],
  };
}
