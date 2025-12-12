import 'dart:convert';
import 'dart:io';

import 'package:room_management/domian/models/enum.dart';
import 'package:room_management/domian/models/patient.dart';
import 'package:room_management/domian/models/room.dart';
import 'package:room_management/domian/models/roomTypes.dart';
import 'package:room_management/domian/services/hospitalManagement.dart';

// Ai Generated
// Data persistence handler
class DataStorage {
  // Save hospital data to JSON file
  Future<void> saveData(HospitalMgr system, String filePath) async {
    try {
      final data = {
        'activePatients': system.activePatients
            .map((patient) => patient.toJson())
            .toList(),
        'recoveredPatients': system.recoveredPatients
            .map((patient) => patient.toJson())
            .toList(),
        'rooms': system.allRooms.map((room) => room.toJson()).toList(),
      };

      final encodedData = const JsonEncoder.withIndent('  ').convert(data);

      final file = File(filePath);
      final dir = Directory(file.parent.path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // First write to a temporary file
      final tempFile = File('${filePath}.tmp');
      await tempFile.writeAsString(encodedData);

      // If successful, move the temp file to the actual file
      await tempFile.rename(filePath);
    } catch (e) {
      throw Exception('Failed to save data: $e');
    }
  }

  // Load hospital data from JSON file
  Future<void> loadData(HospitalMgr system, String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw FileSystemException('File not found', filePath);
      }

      final jsonString = await file.readAsString();
      if (jsonString.trim().isEmpty) return;

      Map<String, dynamic> data;
      try {
        data = jsonDecode(jsonString) as Map<String, dynamic>;
      } on FormatException {
        // Try to load backup file if main file is corrupted
        final backupFile = File('${filePath}.bak');
        if (await backupFile.exists()) {
          final backupJson = await backupFile.readAsString();
          data = jsonDecode(backupJson) as Map<String, dynamic>;
        } else {
          rethrow;
        }
      }

      // Clear existing data
      system.activePatients.clear();
      system.recoveredPatients.clear();
      system.generalRooms.clear();
      system.privateRooms.clear();
      system.emergencyRooms.clear();
      system.icuRooms.clear();
      system.operatingRooms.clear();

      // Load active patients
      if (data['activePatients'] != null) {
        for (final patient in data['activePatients'] as List) {
          system.activePatients.add(
            PatientInfo.fromJson(patient as Map<String, dynamic>),
          );
        }
      }

      // Load recovered patients
      if (data['recoveredPatients'] != null) {
        for (final patient in data['recoveredPatients'] as List) {
          system.recoveredPatients.add(
            PatientInfo.fromJson(patient as Map<String, dynamic>),
          );
        }
      }

      // Load rooms
      if (data['rooms'] != null) {
        final rooms = (data['rooms'] as List)
            .map((r) => HospitalRoom.fromJson(r as Map<String, dynamic>))
            .toList();

        for (final room in rooms) {
          switch (room.roomType) {
            case RoomType.GENERAL_ROOM:
              system.generalRooms.add(room as GeneralRoom);
              break;
            case RoomType.PRIVATE_ROOM:
              system.privateRooms.add(room as PrivateRoom);
              break;
            case RoomType.ICU_ROOM:
              system.icuRooms.add(room as ICURoom);
              break;
            case RoomType.EMERGENCY_ROOM:
              system.emergencyRooms.add(room as EmergencyRoom);
              break;
            case RoomType.OPERATING_ROOM:
              system.operatingRooms.add(room as OperatingRoom);
              break;
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }
}
