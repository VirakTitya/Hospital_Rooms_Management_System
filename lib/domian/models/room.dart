import 'package:uuid/uuid.dart';
import 'bed.dart';
import 'enum.dart';
import 'roomTypes.dart';

var uuid = Uuid().v4();

// Base room class
abstract class HospitalRoom {
  final String roomId;
  final int roomNum;
  final RoomType roomType;
  final List<Bed> beds;

  HospitalRoom({
    String? roomId,
    required this.roomNum,
    required this.roomType,
    required this.beds,
  }) : roomId = roomId ?? uuid;

  // Get first available bed in room
  Bed? getAvailableBed() {
    for (final bed in beds) {
      if (bed.bedStatus == BedStatus.AVAILABLE) return bed;
    }
    return null;
  }

  // Format room type for display
  String formatRoomType(RoomType type) {
    return type
        .toString()
        .split('.')
        .last
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.substring(0, 1).toUpperCase() +
            word.substring(1).toLowerCase())
        .join(' ');
  }

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'roomType': roomType.toString().split('.').last,
    'roomNumber': roomNum,
    'beds': beds.map((bed) => bed.toJson()).toList(),
  };

  // Factory for creating room from JSON
  factory HospitalRoom.fromJson(Map<String, dynamic> json) {
    var roomType = RoomType.values.firstWhere(
      (type) => type.toString().split('.').last == json['roomType'],
      orElse: () => throw FormatException('Invalid room type: ${json['roomType']}'),
    );
    List<Bed> beds = (json['beds'] as List)
        .map((bedJson) => Bed.fromJson(bedJson))
        .toList();

    var roomNumber = json['roomNumber'] as int;

    switch (roomType) {
      case RoomType.GENERAL_ROOM:
        return GeneralRoom(roomNum: roomNumber, beds: beds);
      case RoomType.PRIVATE_ROOM:
        return PrivateRoom(roomNum: roomNumber, beds: beds);
      case RoomType.ICU_ROOM:
        return ICURoom(roomNum: roomNumber, beds: beds);
      case RoomType.EMERGENCY_ROOM:
        return EmergencyRoom(roomNum: roomNumber, beds: beds);
      case RoomType.OPERATING_ROOM:
        return OperatingRoom(roomNum: roomNumber, beds: beds);
    }
  }
}
