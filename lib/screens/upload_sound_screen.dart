// lib/screens/upload_sound_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../api_service.dart';

class UploadSoundScreen extends StatefulWidget {
  const UploadSoundScreen({super.key});

  @override
  State<UploadSoundScreen> createState() => _UploadSoundScreenState();
}

class _UploadSoundScreenState extends State<UploadSoundScreen> {
  bool isUploading = false;

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );
    if (result == null) return;

    final path = result.files.single.path;
    if (path == null) return;

    setState(() => isUploading = true);
    try {
      final uploadedFileName = await ApiService.uploadSound(path);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("✅ Yüklendi: $uploadedFileName")));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Yükleme başarısız")));
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ses Yükle")),
      body: Center(
        child: isUploading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: _pickAndUploadFile,
                icon: const Icon(Icons.upload_file),
                label: const Text("Dosya Seç ve Yükle"),
              ),
      ),
    );
  }
}
