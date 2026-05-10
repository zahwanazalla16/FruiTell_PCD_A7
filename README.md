# FruiTell_PCD_A7
Aplikasi Mobile untuk Mendeteksi Buah dan Tingkat Kematangannya - Tugas Besar PCD Semester 4 - 009 - 026 - 030

FruiTell adalah aplikasi mobile berbasis Flutter yang digunakan untuk mendeteksi tingkat kematangan buah menggunakan YOLO TensorFlow.

# Aplikasi menggunakan:
- Flutter - Framework mobile app. 
- YOLOv8 Nano - AI Object Detection.
- TensorFlow Lite - Menjalankan AI di device.
- Python 3.11 - Environment AI.
- Ultralytics - Library YOLO.
- Camera Package - Mengakses kamera Android.

# Install Sofware:
- Flutter SDK
- Python 3.11
  (Wajib menggunakan Python 3.11 atau jika di mac gunakan python3 / pip3, karena TensorFlow dan YOLO belum stabil di Python 3.14.). 
    - (Mac) Install python / Homebrew (jalankan): brew install python@3.11

Membuat Project Flutter:
- flutter create . --project-name fruitell_pcd_a7

# Install Dependencies Flutter:
- flutter pub add image
- flutter pub add camera
- flutter pub add image_picker
- flutter pub add tflite_flutter
- flutter pub add path_provider
- flutter pub get

# YOLO & TensorFlow
Setup YOLO Environment (jalankan ini di terminal):
- pip install ultralytics

Install YOLO dan TensorFlow:
- windows: py -3.11 -m pip install ultralytics tensorflow
- mac: pip3 install ultralytics tensorflow

Model YOLO yang digunakan YOLOv8 Nano (yolov8n):
- yolo export model=yolov8n.pt format=tflite

Export YOLO ke TensorFlow Lite:
- windows: py -3.11 -m yolo export model=yolov8n.pt format=tflite
- mac: python3 -m yolo export model=yolov8n.pt format=tflite

Menghasilkan:
yolov8n_saved_model/yolov8n_float16.tflite
Pindahkan yolov8n_float16.tflite ke assets/models

- pubspec.yaml (tambahkan):
flutter:
  uses-material-design: true

  assets:
    - assets/models/
    - assets/images/

Kemudian:
- flutter pub get

Kemudian install FastAPI supaya flutter bisa komunikasi ke YOLO (jalankan ini di terminal):
- pip install fastapi uvicorn python-multipart
