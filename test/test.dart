import 'package:test/test.dart';
import 'package:room_management/domian/models/enum.dart';
import 'package:room_management/domian/models/patient.dart';
import 'package:room_management/domian/services/hospitalManagement.dart';

void main() {
  group('Room Management - single file tests', () {
    test('Initial room setup', () {
      final hospital = HospitalMgr();

      expect(hospital.generalRooms.length, equals(10));
      expect(hospital.icuRooms.length, equals(5));
      expect(hospital.privateRooms.length, equals(5));
      expect(hospital.emergencyRooms.length, equals(5));
      expect(hospital.operatingRooms.length, equals(5));
    });

    test('Assign CRITICAL patient -> ICU and bed becomes occupied', () {
      final hospital = HospitalMgr();

      final patient = PatientInfo(
        name: 'John ICU',
        gender: PatientGender.MALE,
        entryDate: DateTime.now(),
        condition: PatientCondition.CRITICAL,
      );

      hospital.assignNewPatient(patient);

      expect(hospital.activePatients, contains(patient));
      final room = hospital.findPatientCurrentRoom(patient);
      expect(room?.roomType, equals(RoomType.ICU_ROOM));

      // bed in that room should reference this patient and be OCCUPIED
      final bed = room?.beds.firstWhere(
        (b) => b.currentPatient?.patientId == patient.patientId,
        orElse: () => throw Exception('Bed not found'),
      );
      expect(bed, isNotNull);
      expect(bed?.bedStatus, equals(BedStatus.OCCUPIED));
    });

    test(
      'Recovering a patient releases bed and moves patient to recovered list',
      () {
        final hospital = HospitalMgr();

        final patient = PatientInfo(
          name: 'Jane ER',
          gender: PatientGender.FEMALE,
          entryDate: DateTime.now(),
          condition: PatientCondition.EMERGENCY,
        );

        hospital.assignNewPatient(patient);
        final roomBefore = hospital.findPatientCurrentRoom(patient);
        expect(roomBefore, isNotNull);

        hospital.changePatientCondition(patient, PatientCondition.RECOVERED);

        expect(hospital.activePatients, isNot(contains(patient)));
        expect(hospital.recoveredPatients, contains(patient));

        final roomAfter = hospital.findPatientCurrentRoom(patient);
        expect(roomAfter, isNull);

        if (roomBefore != null) {
          final available = roomBefore.beds
              .where((b) => b.bedStatus == BedStatus.AVAILABLE)
              .length;
          expect(available, greaterThanOrEqualTo(1));
        }
      },
    );
  });
}
