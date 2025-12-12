import 'package:room_management/domian/models/bed.dart';
import 'package:room_management/domian/models/enum.dart';
import 'package:room_management/domian/models/room.dart';

// General room with 10 beds
class GeneralRoom extends HospitalRoom {
  GeneralRoom({List<Bed>? beds, required int roomNum})
      : super(
          roomType: RoomType.GENERAL_ROOM,
          beds: beds ?? List.generate(10, (_) => Bed()),
          roomNum: roomNum,
        );
}

// Emergency room with 1 bed
class EmergencyRoom extends HospitalRoom {
  EmergencyRoom({List<Bed>? beds, required int roomNum})
      : super(
          roomType: RoomType.EMERGENCY_ROOM,
          beds: beds ?? [Bed()],
          roomNum: roomNum,
        );
}

// Private room with 1 bed
class PrivateRoom extends HospitalRoom {
  PrivateRoom({List<Bed>? beds, required int roomNum})
      : super(
          roomType: RoomType.PRIVATE_ROOM,
          beds: beds ?? [Bed()],
          roomNum: roomNum,
        );
}

// ICU room with 5 beds
class ICURoom extends HospitalRoom {
  ICURoom({List<Bed>? beds, required int roomNum})
      : super(
          roomType: RoomType.ICU_ROOM,
          beds: beds ?? List.generate(5, (_) => Bed()),
          roomNum: roomNum,
        );
}

// Operating room with 1 bed
class OperatingRoom extends HospitalRoom {
  OperatingRoom({List<Bed>? beds, required int roomNum})
      : super(
          roomType: RoomType.OPERATING_ROOM,
          beds: beds ?? [Bed()],
          roomNum: roomNum,
        );
}
