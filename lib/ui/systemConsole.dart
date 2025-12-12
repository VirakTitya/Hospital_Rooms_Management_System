import 'dart:io';
import 'package:room_management/data/dataStorage.dart';
import 'package:room_management/domian/models/enum.dart';
import 'package:room_management/domian/models/patient.dart';
import 'package:room_management/domian/services/hospitalManagement.dart';

// Main console UI for room management
class SystemConsole {
  final HospitalMgr hospitalMgr;
  final DataStorage _dataStorage;
  static const String _dataFilePath = 'data/hospitalData.json';

  SystemConsole()
      : hospitalMgr = HospitalMgr(),
        _dataStorage = DataStorage() {}

  Future<void> start() async {
    // Load previous data if exists
    await _loadData();
    bool isRunning = true;

    while (isRunning) {
      printMenu();
      String? choice = stdin.readLineSync();

      switch (choice) {
        case '1':
          assignNewPatient();
          break;
        case '2':
          changePatientCondition();
          break;
        case '3':
          showPatients();
          break;
        case '4':
          showAvailableRoomAndBed();
          break;
        case '0':
          await _saveData(); // save before exit
          isRunning = false;
          print('Exiting system...');
          break;
        default:
          print('Invalid option. Please try again.');
      }
    }
  }

  void printMenu() {
    print('\n=== Hospital Room Management System ===');
    print('1. Assign new patient');
    print('2. Change patient condition');
    print('3. Show patients');
    print('4. Show available rooms and beds');
    print('0. Exit');
    stdout.write('Enter your choice: ');
  }

  void assignNewPatient() {
    print('\n--- Assign New Patient ---');

    stdout.write('Enter patient name: ');
    final name = stdin.readLineSync() ?? '';

    print('\nSelect gender:');
    print('1. Male');
    print('2. Female');
    stdout.write('Enter choice (1-2): ');
    final genderChoice = stdin.readLineSync();
    final gender = genderChoice == '1'
        ? PatientGender.MALE
        : PatientGender.FEMALE;

    print('\nSelect patient condition:');
    print('1. Stable');
    print('2. Emergency');
    print('3. Critical');
    print('4. Needs Surgery');
    stdout.write('Enter choice (1-4): ');

    final conditionChoice = stdin.readLineSync();
    PatientCondition condition;
    switch (conditionChoice) {
      case '1':
        condition = PatientCondition.STABLE;
        break;
      case '2':
        condition = PatientCondition.EMERGENCY;
        break;
      case '3':
        condition = PatientCondition.CRITICAL;
        break;
      case '4':
        condition = PatientCondition.NEED_SURGERY;
        break;
      default:
        print('Invalid condition. Defaulting to Stable.');
        condition = PatientCondition.STABLE;
    }

    if (condition == PatientCondition.STABLE) {
      stdout.write('\nRequest private room? (y/n): ');
      final privateRoom = stdin.readLineSync()?.toLowerCase() == 'y';

      final patient = PatientInfo(
        name: name,
        gender: gender,
        entryDate: DateTime.now(),
        condition: condition,
        wantsPrivateRoom: privateRoom,
      );
      hospitalMgr.assignNewPatient(patient);
    } else {
      final patient = PatientInfo(
        name: name,
        gender: gender,
        entryDate: DateTime.now(),
        condition: condition,
      );
      hospitalMgr.assignNewPatient(patient);
    }

    print('Patient has been assigned successfully.');
    _saveData();
  }

  void showPatients() {
    print('\n--- Current Patients ---');

    if (hospitalMgr.activePatients.isEmpty) {
      print('No active patients.');
    } else {
      print('\nActive Patients:');
      for (final patient in hospitalMgr.activePatients) {
        final room = hospitalMgr.findPatientCurrentRoom(patient);
        String? bedNumber;

        // Find patient's bed number
        if (room != null) {
          final bedIndex = room.beds.indexWhere(
            (bed) => bed.currentPatient?.patientId == patient.patientId,
          );
          if (bedIndex != -1) {
            bedNumber = (bedIndex + 1).toString();
          }
        }

        final gender = hospitalMgr.formatEnumType(
          patient.gender.toString().split('.').last,
        );
        final condition = hospitalMgr.formatEnumType(
          patient.condition.toString().split('.').last,
        );
        final roomType = hospitalMgr.formatEnumType(
          room?.roomType.toString().split('.').last ?? 'UNKNOWN',
        );

        print(
          '  Name: ${patient.name} | Gender: $gender | Condition: $condition | '
          'Room Type: $roomType | Room Number: ${room?.roomNum} | Bed Number: $bedNumber',
        );
      }
    }

    if (hospitalMgr.recoveredPatients.isNotEmpty) {
      print('\nRecovered Patients:');
      for (final patient in hospitalMgr.recoveredPatients) {
        print('- Name: ${patient.name}');
        print('  Entry Date: ${patient.entryDate}');
        print('  Leave Date: ${patient.leaveDate}');
        print('');
      }
    }
  }

  void showAvailableRoomAndBed() {
    print('\n--- Available Rooms and Beds ---');

    void printRoomStatus(String type, List rooms) {
      print('\n$type:');
      for (final room in rooms) {
        final availableBeds = room.beds
            .where((bed) => bed.bedStatus == BedStatus.AVAILABLE)
            .length;
        final totalBeds = room.beds.length;
        print(
          'Room ${room.roomNum}: $availableBeds/$totalBeds beds available',
        );

        for (var i = 0; i < room.beds.length; i++) {
          final bed = room.beds[i];
          print(
            '  Bed ${i + 1}: Status = ${hospitalMgr.formatEnumType(bed.bedStatus.toString().split('.').last)}, '
            '  Has Patient = ${bed.currentPatient != null ? 'Yes (${bed.currentPatient!.name})' : 'No'}',
          );
        }
      }
    }

    printRoomStatus('Emergency Rooms', hospitalMgr.emergencyRooms);
    printRoomStatus('General Rooms', hospitalMgr.generalRooms);
    printRoomStatus('Private Rooms', hospitalMgr.privateRooms);
    printRoomStatus('ICU Rooms', hospitalMgr.icuRooms);
    printRoomStatus('Operating Rooms', hospitalMgr.operatingRooms);
  }

  void changePatientCondition() {
    print('\n--- Change Patient Condition ---');

    if (hospitalMgr.activePatients.isEmpty) {
      print('No active patients.');
      return;
    }

    print('Select patient:');
    for (var i = 0; i < hospitalMgr.activePatients.length; i++) {
      final patient = hospitalMgr.activePatients[i];
      final room = hospitalMgr.findPatientCurrentRoom(patient);
      print(
        '${i + 1}. ${patient.name} (Current: ${hospitalMgr.formatEnumType(patient.condition.toString().split('.').last)}, Room: ${hospitalMgr.formatEnumType(room?.roomType.toString().split('.').last ?? 'UNKNOWN')})',
      );
    }
    stdout.write('Enter patient number: ');

    final patientChoice = int.tryParse(stdin.readLineSync() ?? '');
    if (patientChoice == null ||
        patientChoice < 1 ||
        patientChoice > hospitalMgr.activePatients.length) {
      print('Invalid patient selection.');
      return;
    }

    final patient = hospitalMgr.activePatients[patientChoice - 1];

    print('\nSelect new condition:');
    print('1. Emergency');
    print('2. Stable');
    print('3. Critical');
    print('4. Needs Surgery');
    print('5. Recovered');
    stdout.write('Enter choice (1-5): ');

    final conditionChoice = stdin.readLineSync();
    PatientCondition newCondition;
    switch (conditionChoice) {
      case '1':
        newCondition = PatientCondition.EMERGENCY;
        break;
      case '2':
        newCondition = PatientCondition.STABLE;
        break;
      case '3':
        newCondition = PatientCondition.CRITICAL;
        break;
      case '4':
        newCondition = PatientCondition.NEED_SURGERY;
        break;
      case '5':
        newCondition = PatientCondition.RECOVERED;
        break;
      default:
        print('Invalid condition selection.');
        return;
    }

    if (newCondition == PatientCondition.STABLE) {
      stdout.write('\nRequest private room? (y/n): ');
      final privateRoom = stdin.readLineSync()?.toLowerCase() == 'y';
      patient.wantsPrivateRoom = privateRoom;
    }

    try {
      hospitalMgr.changePatientCondition(patient, newCondition);
      print('Patient condition updated successfully.');

      if (newCondition == PatientCondition.RECOVERED) {
        print('Patient has been discharged.');
      } else {
        final newRoom = hospitalMgr.findPatientCurrentRoom(patient);
        print(
          'Patient moved to ${newRoom?.roomType.toString().split('.').last.replaceAll('_', ' ')}',
        );
      }
      _saveData();
    } catch (e) {
      print('Error updating patient condition: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      await _dataStorage.saveData(hospitalMgr, _dataFilePath);
      print('Data saved successfully.');
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      await _dataStorage.loadData(hospitalMgr, _dataFilePath);
      print('Previous data loaded successfully.');
    } catch (e) {
      print('No previous data found or error loading data: $e');
    }
  }
}
