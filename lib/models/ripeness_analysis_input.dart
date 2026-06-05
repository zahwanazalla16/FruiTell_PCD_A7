/// Input data untuk ripeness analysis
class RipenessAnalysisInput {
  RipenessAnalysisInput({
    required this.fruitLabel, // "apple", "banana", "orange", etc
    required this.confidence, // 0.0 - 1.0 (confidence dari YOLO)
    required this.averageLuma, // Brightness dari image (0-255)
    this.colorProfile = const {}, // Optional: {R%, G%, B%, H, S, V}
    this.textureScore = 0.0, // Optional: 0-100 (halus=tinggi, kasar=rendah)
    this.sizeScore = 0.0, // Optional: 0-100 (estimasi ukuran relatif)
    this.captureTime,
    this.temperature = 25.0, // Default room temperature
  });

  final String fruitLabel;
  final double confidence;
  final double averageLuma;
  final Map<String, double> colorProfile;
  final double textureScore;
  final double sizeScore;
  final DateTime? captureTime;
  final double temperature;

  @override
  String toString() => '''
RipenessAnalysisInput(
  label: $fruitLabel,
  confidence: $confidence,
  luma: $averageLuma,
  texture: $textureScore,
  size: $sizeScore
)''';
}
