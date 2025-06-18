import 'package:flutter/material.dart';
import '../api_service.dart';
import 'upload_sound_screen.dart';
import 'add_time_screen.dart';
import 'edit_time_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> schedule = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSchedule();
  }

  Future<void> fetchSchedule() async {
    setState(() => isLoading = true);
    try {
      final data = await ApiService.getTimes();
      setState(() => schedule = data);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ Saatler alınamadı')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteTime(String day, String time) async {
    try {
      await ApiService.deleteTime(day, time);
      fetchSchedule();
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ Silinemedi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ders Zil Sistemi"),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () async {
              try {
                await ApiService.testBell();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('🔔 Zil çaldı')));
              } catch (_) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('❌ Çalamadı')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UploadSoundScreen()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: schedule.map((dayEntry) {
                final day = dayEntry['day'];
                final times = List<Map<String, dynamic>>.from(
                  dayEntry['times'],
                );

                return ExpansionTile(
                  title: Text(day.toUpperCase()),
                  children: times.map((entry) {
                    final time = entry['time'];
                    final sound = entry['sound'];
                    return ListTile(
                      title: Text('$time (${sound.toString()})'),
                      trailing: Wrap(
                        spacing: 12,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditTimeScreen(
                                    oldDay: day,
                                    oldTime: time,
                                    oldSound: sound,
                                  ),
                                ),
                              );
                              fetchSchedule();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteTime(day, time),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTimeScreen()),
          );
          fetchSchedule();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
