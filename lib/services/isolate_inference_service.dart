import 'dart:io';
import 'dart:isolate';
import 'dart:async';
import 'inference_service.dart';
import '../models/detection_result.dart';

/// Service untuk menjalankan model inference di background thread (Isolate)
/// Tujuan: Tidak block Main Thread UI
class IsolateInferenceService {
  static final IsolateInferenceService _instance =
      IsolateInferenceService._internal();

  factory IsolateInferenceService() {
    return _instance;
  }

  IsolateInferenceService._internal();

  static Isolate? _isolate;
  static SendPort? _sendPort;
  static final Completer<SendPort> _sendPortCompleter =
      Completer<SendPort>();

  /// Inisialisasi Isolate
  static Future<void> initModel() async {
    if (_isolate != null) return;

    print('[IsolateInference] Starting initialization...');
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _isolateEntry,
      receivePort.sendPort,
    );
    print('[IsolateInference] Isolate spawned');

    _sendPort = await receivePort.first;
    _sendPortCompleter.complete(_sendPort!);
    print('[IsolateInference] SendPort received, Isolate ready');
  }

  /// Entry point untuk Isolate
  static void _isolateEntry(SendPort mainSendPort) async {
    final port = ReceivePort();
    mainSendPort.send(port.sendPort);

    print('[Isolate] Entry point called');
    final inferenceService = InferenceService();
    print('[Isolate] InferenceService created');

    // Inisialisasi model di Isolate thread - HARUS AWAIT
    try {
      print('[Isolate] Initializing model...');
      await inferenceService.initModel();
      print('[Isolate] Model loaded successfully');
    } catch (e) {
      print('[Isolate] ERROR loading model: $e');
    }

    // BARU setelah model ready, mulai listen untuk messages
    print('[Isolate] Starting message listener');
    port.listen((dynamic message) async {
      try {
        if (message is _DetectMessage) {
          print('[Isolate] Processing detection message for: ${message.imageFile.path}');
          final result = await inferenceService.detectDominantFromFile(
            message.imageFile,
            overwriteOriginal: message.overwriteOriginal,
            fastMode: message.fastMode,
          );
          print('[Isolate] Detection result: $result');
          message.responsePort.send(result);
        } else if (message is _InitMessage) {
          print('[Isolate] Processing init message');
          await inferenceService.initModel();
          message.responsePort.send(null);
        }
      } catch (e) {
        print('[Isolate] ERROR during detection: $e');
        message.responsePort.send(_ErrorResult(error: e.toString()));
      }
    });
  }

  /// Jalankan deteksi di Isolate
  static Future<DominantDetection?> detectAsync(
    File imageFile, {
    bool overwriteOriginal = false,
    bool fastMode = false,
  }) async {
    print('[IsolateInference] detectAsync called');
    final sendPort = await _sendPortCompleter.future;
    final receivePort = ReceivePort();

    print('[IsolateInference] Sending detect message');
    sendPort.send(
      _DetectMessage(
        imageFile: imageFile,
        responsePort: receivePort.sendPort,
        overwriteOriginal: overwriteOriginal,
        fastMode: fastMode,
      ),
    );

    final result = await receivePort.first;
    print('[IsolateInference] Received result from Isolate: $result');

    if (result is _ErrorResult) {
      throw Exception(result.error);
    }

    return result as DominantDetection?;
  }

  /// Dispose Isolate
  static void dispose() {
    if (_isolate != null) {
      _isolate!.kill(priority: Isolate.immediate);
      _isolate = null;
      _sendPort = null;
      print('[IsolateInference] Isolate terminated');
    }
  }
}

// Message classes untuk komunikasi antar Isolate
class _InitMessage {
  final SendPort responsePort;
  _InitMessage({required this.responsePort});
}

class _DetectMessage {
  final File imageFile;
  final SendPort responsePort;
  final bool overwriteOriginal;
  final bool fastMode;

  _DetectMessage({
    required this.imageFile,
    required this.responsePort,
    this.overwriteOriginal = false,
    this.fastMode = false,
  });
}

class _ErrorResult {
  final String error;
  _ErrorResult({required this.error});
}
