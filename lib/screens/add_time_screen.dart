import 'package:flutter/material.dart';
import '../api_service.dart';

class AddTimeScreen extends StatefulWidget {
  const AddTimeScreen({super.key});

  @override
  State<AddTimeScreen> createState() => _AddTimeScreenState();
}

class _AddTimeScreenState extends State<AddTimeScreen> {
  String selectedDay = 'monday';
  TimeOfDay selectedTime = TimeOfDay.now();
  String? selectedSound;
  String name = "";
  List<String> sounds = [];
  bool isLoading = false;

  List<String> days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  void initState() {
    super.initState();
    fetchSounds();
  }

  Future<void> fetchSounds() async {
    try {
      final fetched = await ApiService.getSounds();
      setState(() => sounds = fetched);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ Sesler yüklenemedi')));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> _submit() async {
    if (selectedSound == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❗ Lütfen ses seçin')));
      return;
    }

    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❗ Lütfen alarm ismi girin')),
      );
      return;
    }

    setState(() => isLoading = true);
    String time =
        selectedTime.hour.toString().padLeft(2, '0') +
        ':' +
        selectedTime.minute.toString().padLeft(2, '0');

    try {
      await ApiService.addTime(selectedDay, time, selectedSound!, name.trim());

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Saat eklendi')));
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ Eklenemedi')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Saat Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedDay,
              onChanged: (value) => setState(() => selectedDay = value!),
              items: days
                  .map(
                    (day) => DropdownMenuItem(
                      value: day,
                      child: Text(day.toUpperCase()),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.access_time),
              label: Text("Saat Seç (${selectedTime.format(context)})"),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: selectedSound,
              hint: const Text("Ses Seç"),
              isExpanded: true,
              onChanged: (value) => setState(() => selectedSound = value),
              items: sounds
                  .map(
                    (sound) =>
                        DropdownMenuItem(value: sound, child: Text(sound)),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Alarm İsmi',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => name = val,
            ),
            const Spacer(),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save),
                    label: const Text("Kaydet"),
                  ),
          ],
        ),
      ),
    );
  }
}
