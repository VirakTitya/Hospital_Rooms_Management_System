import 'package:room_management/domian/models/enum.dart';
import 'package:room_management/domian/models/patient.dart';
import 'package:room_management/domian/models/room.dart';
import 'package:room_management/domian/models/roomTypes.dart';

// Hospital management system
class HospitalMgr {
  final List<GeneralRoom> generalRooms;
  final List<PrivateRoom> privateRooms;
  final List<EmergencyRoom> emergencyRooms;
  final List<ICURoom> icuRooms;
  final List<OperatingRoom> operatingRooms;

  int nextRoomNum = 1;
  int allocateRoomNum() => nextRoomNum++;

  HospitalMgr()
      : generalRooms = [],
        privateRooms = [],
        emergencyRooms = [],
        icuRooms = [],
        operatingRooms = [] {
    // Initialize emergency rooms
    for (int i = 0; i < 5; i++) {
      emergencyRooms.add(EmergencyRoom(roomNum: allocateRoomNum()));
    }
    // Initialize general rooms
    for (int i = 0; i < 10; i++) {
      generalRooms.add(GeneralRoom(roomNum: allocateRoomNum()));
    }
    // Initialize private rooms
    for (int i = 0; i < 5; i++) {
      privateRooms.add(PrivateRoom(roomNum: allocateRoomNum()));
    }
    // Initialize ICU rooms
    for (int i = 0; i < 5; i++) {
      icuRooms.add(ICURoom(roomNum: allocateRoomNum()));
    }
    // Initialize operating rooms
    for (int i = 0; i < 5; i++) {
      operatingRooms.add(OperatingRoom(roomNum: allocateRoomNum()));
    }
  }

  final List<PatientInfo> activePatients = [];
  final List<PatientInfo> recoveredPatients = [];

  // Format enum type for display
  String formatEnumType(Object typeRaw) {
    final typeStr = typeRaw
        .toString()
        .split('.')
        .last
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}')
        .join(' ');
    return typeStr;
  }

  // Assign new patient to appropriate room
  void assignNewPatient(PatientInfo patient) {
    activePatients.add(patient);

    switch (patient.condition) {
      case PatientCondition.CRITICAL:
        assignToICU(patient);
        break;
      case PatientCondition.EMERGENCY:
        assignToEmergency(patient);
        break;
      case PatientCondition.STABLE:
        if (patient.wantsPrivateRoom) {
          assignToPrivate(patient);
        } else {
          assignToGeneral(patient);
        }
        break;
      case PatientCondition.NEED_SURGERY:
        assignToOperating(patient);
        break;
      case PatientCondition.RECOVERED:
        markRecovered(patient);
        break;
    }
  }

  // Transfer patient to different room type
  void transferPatient(PatientInfo patient, RoomType newRoomType) {
    if (!activePatients.contains(patient)) {
      throw Exception('Patient is not currently admitted');
    }
    releasePatientBed(patient);

    switch (newRoomType) {
      case RoomType.ICU_ROOM:
        patient.condition = PatientCondition.CRITICAL;
        assignToICU(patient);
        break;
      case RoomType.EMERGENCY_ROOM:
        patient.condition = PatientCondition.EMERGENCY;
        assignToEmergency(patient);
        break;
      case RoomType.OPERATING_ROOM:
        patient.condition = PatientCondition.NEED_SURGERY;
        assignToOperating(patient);
        break;
      case RoomType.PRIVATE_ROOM:
        patient.condition = PatientCondition.STABLE;
        patient.wantsPrivateRoom = true;
        assignToPrivate(patient);
        break;
      case RoomType.GENERAL_ROOM:
        patient.condition = PatientCondition.STABLE;
        patient.wantsPrivateRoom = false;
        assignToGeneral(patient);
        break;
    }
  }

  // Assign patient to ICU
  void assignToICU(PatientInfo patient) {
    for (var room in icuRooms) {
      final availableBed = room.getAvailableBed();
      if (availableBed != null) {
        availableBed.assignPatient(patient);
        patient.statusHistory.add(formatEnumType(RoomType.ICU_ROOM));
        return;
      }
    }
    throw Exception('No ICU beds available');
  }

  // Assign patient to Emergency
  void assignToEmergency(PatientInfo patient) {
    for (var room in emergencyRooms) {
      final availableBed = room.getAvailableBed();
      if (availableBed != null) {
        availableBed.assignPatient(patient);
        patient.statusHistory.add(formatEnumType(RoomType.EMERGENCY_ROOM));
        return;
      }
    }
    throw Exception('No Emergency beds available');
  }

  // Assign patient to General room
  void assignToGeneral(PatientInfo patient) {
    for (var room in generalRooms) {
      final availableBed = room.getAvailableBed();
      if (availableBed != null) {
        availableBed.assignPatient(patient);
        patient.statusHistory.add(formatEnumType(RoomType.GENERAL_ROOM));
        return;
      }
    }
    throw Exception('No General beds available');
  }

  // Assign patient to Private room
  void assignToPrivate(PatientInfo patient) {
    for (var room in privateRooms) {
      final availableBed = room.getAvailableBed();
      if (availableBed != null) {
        availableBed.assignPatient(patient);
        patient.statusHistory.add(formatEnumType(RoomType.PRIVATE_ROOM));
        return;
      }
    }
    // If no private room available, assign to general room
    assignToGeneral(patient);
  }

  // Assign patient to Operating room
  void assignToOperating(PatientInfo patient) {
    for (var room in operatingRooms) {
      final availableBed = room.getAvailableBed();
      if (availableBed != null) {
        availableBed.assignPatient(patient);
        patient.statusHistory.add(formatEnumType(RoomType.OPERATING_ROOM));
        return;
      }
    }
    throw Exception('No Operating Room beds available');
  }

  // Mark patient as recovered and discharge
  void markRecovered(PatientInfo patient) {
    patient.leaveDate = DateTime.now();
    patient.statusHistory.add('Discharged - Recovered');
    recoveredPatients.add(patient);
    releasePatientBed(patient);
    activePatients.remove(patient);
  }

  // Check if room has availability
  bool hasAvailability(HospitalRoom room) => room.getAvailableBed() != null;

  // Find patient's current room
  HospitalRoom? findPatientCurrentRoom(PatientInfo patient) {
    for (var room in allRooms) {
      for (var bed in room.beds) {
        if (bed.currentPatient?.patientId == patient.patientId) {
          return room;
        }
      }
    }
    return null;
  }

  // Release patient's bed
  void releasePatientBed(PatientInfo patient) {
    for (var room in allRooms) {
      for (var bed in room.beds) {
        if (bed.currentPatient?.patientId == patient.patientId) {
          bed.releasePatient();
          return;
        }
      }
    }
  }

  // Get all rooms
  List<HospitalRoom> get allRooms => [
    ...emergencyRooms,
    ...generalRooms,
    ...icuRooms,
    ...privateRooms,
    ...operatingRooms,
  ];

  // Change patient condition and move to appropriate room
  void changePatientCondition(PatientInfo patient, PatientCondition newCondition) {
    if (!activePatients.contains(patient)) {
      throw Exception('Patient is not currently admitted');
    }

    if (patient.condition == newCondition) {
      return;
    }

    if (newCondition == PatientCondition.RECOVERED) {
      markRecovered(patient);
      return;
    }

    final roomTypeMap = {
      PatientCondition.CRITICAL: RoomType.ICU_ROOM,
      PatientCondition.EMERGENCY: RoomType.EMERGENCY_ROOM,
      PatientCondition.NEED_SURGERY: RoomType.OPERATING_ROOM,
      PatientCondition.STABLE: patient.wantsPrivateRoom
          ? RoomType.PRIVATE_ROOM
          : RoomType.GENERAL_ROOM,
    };

    final newRoomType = roomTypeMap[newCondition];
    if (newRoomType != null) {
      transferPatient(patient, newRoomType);
    }
  }
}
