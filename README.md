# 📱 Smart Patrol Vision — Logbook App AI

Aplikasi Flutter untuk inspeksi dan pencatatan kerusakan jalan secara cerdas, dilengkapi dengan fitur **live camera detection overlay**, **mock AI detection (RDD-2022)**, dan **pengolahan citra digital (PCD)** langsung di perangkat mobile.

---

## 🗂️ Struktur Proyek

- 📁 `lib/`
  - 📁 `features/`
    - 📁 `auth/`
      - 📄 `login_controller.dart`
      - 📄 `login_view.dart`
    - 📁 `logbook/`
      - 📄 `log_controller.dart`
      - 📄 `log_editor_page.dart`
      - 📄 `log_view.dart`
    - 📁 `models/`
      - 📄 `log_model.dart`
      - 📄 `log_model.g.dart`
    - 📁 `onboarding/`
      - 📄 `onboarding_view.dart`
    - 📁 `vision/`
      - 📄 `damage_painter.dart`
      - 📄 `detection_result.dart`
      - 📄 `image_processor.dart`
      - 📄 `pcd_result_view.dart`
      - 📄 `vision_controller.dart`
      - 📄 `vision_view.dart`
  - 📁 `helpers/`
    - 📄 `log_helper.dart`
  - 📁 `services/`
    - 📄 `access_control_service.dart`
    - 📄 `mongo_service.dart`
  - 📄 `main.dart`
---

## ✨ Fitur Utama

### 📷 Smart Patrol Vision
- Live preview kamera full layar tanpa distorsi
- Overlay deteksi kerusakan jalan secara real-time
- Mock AI detection (simulasi YOLO) bergerak setiap 3 detik
- Crosshair statis saat belum ada deteksi
- Toggle flashlight dan overlay via AppBar
- Auto-dispose kamera saat aplikasi masuk background

### 🛣️ Deteksi Kerusakan RDD-2022
| Kode | Tipe Kerusakan | Warna |
|------|---------------|-------|
| D00 | Longitudinal Crack | 🟢 Hijau |
| D10 | Transverse Crack | 🟡 Kuning |
| D20 | Alligator Crack | 🟠 Oranye |
| D40 | Pothole | 🔴 Merah |

### 🧪 Pengolahan Citra Digital (ETS)
| Operasi | Metode |
|---------|--------|
| Grayscale | Weighted average: `0.299R + 0.587G + 0.114B` |
| Contrast Enhancement | `clamp((pixel - 128) × 1.8 + 128, 0, 255)` |
| Histogram Equalization | CDF-based lookup table |
| Konvolusi Sharpen | Kernel `[[0,-1,0],[-1,5,-1],[0,-1,0]]` |
| Konvolusi Edge Detection | Kernel `[[-1,-1,-1],[-1,8,-1],[-1,-1,-1]]` |
| Median Filter | Jendela 3×3, noise reduction |

### 📓 Logbook
- Tambah, edit, dan hapus catatan lapangan
- Sinkronisasi dengan MongoDB
- Role-based access control (owner, Ketua, viewer)
- Indikator sinkronisasi cloud

---

## 🚀 Cara Menjalankan

### 1. Clone & Install Dependencies
```bash
git clone <repository-url>
cd logbook_appai_001
flutter pub get
```

### 2. Konfigurasi Environment
Buat file `.env` di root proyek:
```env
MONGO_URI=your_mongodb_connection_string
```

### 3. Konfigurasi Android
Tambahkan permission di `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

Pastikan `minSdkVersion` di `android/app/build.gradle`:
```gradle
minSdkVersion 21
```

### 4. Jalankan Aplikasi
```bash
flutter run
```

---

## 📦 Dependencies

```yaml
dependencies:
  camera: ^0.11.0
  permission_handler: ^11.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  mongo_dart: ^0.10.5
  flutter_dotenv: ^6.0.0
  image: ^4.1.7
  connectivity_plus: ^7.0.0
  intl: ^0.20.2
  flutter_markdown: ^0.7.7+1
  shared_preferences: ^2.2.2
```

---

## 🏗️ Arsitektur

### UI Layer
| Komponen | Tanggung Jawab |
|----------|---------------|
| `VisionView` | Menampilkan Stack berlapis: CameraPreview + CustomPaint overlay |
| `DamagePainter` | Menggambar crosshair, kotak deteksi, dan label berbasis severity |
| `PcdResultView` | Menampilkan 7 hasil pengolahan citra dalam ListView |
| `LogView` | Halaman utama logbook dengan navigasi ke Vision |

### Logic Layer
| Komponen | Tanggung Jawab |
|----------|---------------|
| `VisionController` | Lifecycle kamera, mock detection timer, flashlight, overlay toggle |
| `ImageProcessor` | Operasi PCD: grayscale, kontras, histogram, konvolusi, median filter |
| `LogController` | CRUD logbook, sinkronisasi MongoDB, state management |
| `AccessControlService` | Role-based permission (Ketua, Anggota, viewer) Asisten

### Data Layer
| Komponen | Tanggung Jawab |
|----------|---------------|
| `MongoService` | Koneksi dan operasi ke MongoDB Atlas |
| `LogModel` | Model data logbook dengan Hive adapter |
| `DetectionResult` | DTO hasil deteksi: box, label, score |

---

## 📸 Alur Penggunaan Vision & PCD

1. **Buka aplikasi** → Login → `LogView` tampil
2. **Tap ikon kamera** di AppBar → navigasi ke `VisionView`
3. **Kamera aktif** → live preview full layar → crosshair muncul
4. **Mock detection berjalan** setiap 3 detik → kotak deteksi berpindah posisi secara acak dengan warna sesuai severity
5. **Tap FAB** 📷 → `takePhoto()` dipanggil → foto tersimpan di temporary directory
6. **Navigasi otomatis** ke `PcdResultView` → `ImageProcessor.processAll()` berjalan
7. **Tampil 7 hasil** pengolahan citra:

| No | Operasi | Keterangan |
|----|---------|------------|
| 1 | Original | Foto asli tanpa perubahan |
| 2 | Grayscale | Konversi ke skala abu-abu |
| 3 | Contrast Enhancement | Peningkatan kontras dengan factor 1.8 |
| 4 | Histogram Equalization | Perataan distribusi intensitas piksel |
| 5 | Konvolusi Sharpen | Penajaman tepi dan detail |
| 6 | Konvolusi Edge Detection | Deteksi tepi objek |
| 7 | Median Filter | Pengurangan noise |

---

## 👥 Role & Access Control

| Role | Buat | Edit | Hapus |
|------|------|------|-------|
| Ketua | ✅ | ✅ (semua) | ✅ (semua) |
| Anggota | ✅ | ✅ (milik sendiri) | ✅ (milik sendiri) |
| Asisten | ❌ | ❌ | ❌ |

---

## 📋 Task Completion

| Task | Deskripsi | Status |
|------|-----------|--------|
| Task 2 | Camera Eye — inisialisasi & live preview | ✅ |
| Task 3 | Dynamic Interface Overlay — crosshair & label | ✅ |
| Task 4 | Mock Detector & Lifecycle Safety | ✅ |
| Homework 1 | Flashlight & Overlay Toggle | ✅ |
| Homework 2 | Informative Vision State | ✅ |
| Homework 3 | Detection Style & Color Branding | ✅ |
| ETS PCD | Pengolahan citra pada foto kamera | ✅ |

---

## 🧑‍💻 Teknologi

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Dart](https://img.shields.io/badge/Dart-3.x-blue)
![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-green)
![Hive](https://img.shields.io/badge/Hive-Local%20DB-orange)