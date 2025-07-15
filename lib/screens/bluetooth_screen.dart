import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final List<BluetoothDevice> _devices = [];
  BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!_devices.contains(result.device)) {
          setState(() {
            _devices.add(result.device);
          });
        }
      }
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }

      await device.connect();
      setState(() {
        _connectedDevice = device;
      });

      final mac = device.remoteId.str;
      print("Bağlanılan cihaz MAC adresi: $mac");
      await sendBluetoothMac(mac);
    } catch (e) {
      print("Bağlanma hatası: $e");
    }
  }

  void _disconnectFromDevice() async {
    try {
      await _connectedDevice?.disconnect();
    } catch (e) {
      print("Bağlantıyı kesme hatası: $e");
    } finally {
      setState(() {
        _connectedDevice = null;
      });
    }
  }

  Future<void> sendBluetoothMac(String mac) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.8:5001/api/bluetooth-connect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mac': mac}),
      );

      if (response.statusCode == 200) {
        print("✅ MAC gönderildi: $mac");
      } else {
        print("❌ MAC gönderme başarısız: ${response.body}");
      }
    } catch (e) {
      print("❌ MAC gönderme hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedDevices = [
      if (_connectedDevice != null) _connectedDevice!,
      ..._devices.where((d) => d.remoteId != _connectedDevice?.remoteId),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Cihazlar")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _startScan,
            child: const Text("Cihazları Tara"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: sortedDevices.length,
              itemBuilder: (context, index) {
                final device = sortedDevices[index];
                final isConnected =
                    device.remoteId == _connectedDevice?.remoteId;

                return ListTile(
                  title: Text(
                    device.platformName.isNotEmpty
                        ? device.platformName
                        : "Bilinmeyen cihaz",
                  ),
                  subtitle: Text(device.remoteId.str),
                  trailing: ElevatedButton(
                    onPressed: () {
                      if (isConnected) {
                        _disconnectFromDevice();
                      } else {
                        _connectToDevice(device);
                      }
                    },
                    child: Text(isConnected ? "Bağlantıyı Kes" : "Bağlan"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
