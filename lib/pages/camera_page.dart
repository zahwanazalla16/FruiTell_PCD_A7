import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/inference_service.dart';
import 'dart:io';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  final _inferenceService = InferenceService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
    _inferenceService.initModel(); // Load model AI saat masuk halaman
  }

  Future<void> _setupCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    await _controller!.initialize();
    setState(() {});
  }

  Future<void> _captureAndDetect() async {
    if (_controller == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final image = await _controller!.takePicture();
      // Jalankan AI (PCD & Inference)
      await _inferenceService.runInference(File(image.path));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Analisis Selesai! Cek Log/Database.")),
        );
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("FruiTell Detector")),
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Pastikan preview kamera mengisi seluruh area layar
            Positioned.fill(child: CameraPreview(_controller!)),
            if (_isProcessing)
              const Positioned.fill(
                child: Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _captureAndDetect,
        label: Text(_isProcessing ? "Berpikir..." : "Deteksi Buah"),
        icon: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _inferenceService.close();
    super.dispose();
  }
}
