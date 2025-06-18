import 'package:flutter/material.dart';
import '../api_service.dart';

class EditTimeScreen extends StatefulWidget {
  final String oldDay;
  final String oldTime;
  final String oldSound;

  const EditTimeScreen({
    super.key,
    required this.oldDay,
    required this.oldTime,
    required this.oldSound,
  });

  @override
  State<EditTimeScreen> createState() => _EditTimeScreenState();
}

class _EditTimeScreenState extends State<EditTimeScreen> {
  late String selectedDay;
  late TimeOfDay selectedTime;
  late String selectedSound;
  List<String> sounds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedDay = widget.oldDay.toLowerCase(); // ✅ küçük harfe çevir
    selectedTime = _parseTime(widget.oldTime);
    selectedSound = widget.oldSound;
    fetchSounds();
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> fetchSounds() async {
    try {
      final fetchedSounds = await ApiService.getSounds();
      setState(() {
        sounds = fetchedSounds;
        if (!sounds.contains(selectedSound)) {
          selectedSound = sounds.isNotEmpty ? sounds.first : "bell.mp3";
        }
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Sesler yüklenemedi")));
    }
  }

  Future<void> submit() async {
    final formattedTime =
        "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";

    try {
      await ApiService.updateTime(
        oldDay: widget.oldDay,
        oldTime: widget.oldTime,
        newDay: selectedDay,
        newTime: formattedTime,
        newSound: selectedSound,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Güncellendi")));
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Güncellenemedi")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Zili Düzenle")),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    items:
                        const [
                              "monday",
                              "tuesday",
                              "wednesday",
                              "thursday",
                              "friday",
                              "saturday",
                              "sunday",
                            ]
                            .map(
                              (day) => DropdownMenuItem(
                                value: day,
                                child: Text(day.toUpperCase()),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedDay = val);
                    },
                    decoration: const InputDecoration(labelText: "Gün"),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setState(() => selectedTime = picked);
                      }
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text("Saat Seç (${selectedTime.format(context)})"),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedSound,
                    items: sounds.map((sound) {
                      return DropdownMenuItem(value: sound, child: Text(sound));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedSound = val);
                    },
                    decoration: const InputDecoration(labelText: "Ses Seç"),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: submit,
                    icon: const Icon(Icons.save),
                    label: const Text("Kaydet"),
                  ),
                ],
              ),
            ),
    );
  }
}
