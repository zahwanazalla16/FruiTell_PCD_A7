class DetectionResult {
  DetectionResult({
    required this.label,
    required this.confidence,
    required this.ripeness,
    required this.freshness,
    required this.bestBefore,
    required this.tips,
  });

  final String label;
  final double confidence;
  final String ripeness;
  final String freshness;
  final String bestBefore;
  final List<String> tips;
}
