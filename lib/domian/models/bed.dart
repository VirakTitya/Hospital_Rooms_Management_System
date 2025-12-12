import 'package:room_management/domian/models/enum.dart';
import 'package:uuid/uuid.dart';
import 'patient.dart'; // My patient info model

class Bed {
  final String bedId;
  PatientInfo? currentPatient;
  BedStatus bedStatus;

  Bed({String? bedId, this.currentPatient, this.bedStatus = BedStatus.AVAILABLE})
      : bedId = bedId ?? Uuid().v4();

  // Assign a patient to this bed
  void assignPatient(PatientInfo patient) {
    currentPatient = patient;
    patient.assignBed(bedId);
    bedStatus = BedStatus.OCCUPIED;
  }

  // Release the patient from this bed
  void releasePatient() {
    currentPatient?.releaseBed();
    currentPatient = null;
    bedStatus = BedStatus.AVAILABLE;
  }

  Map<String, dynamic> toJson() {
    // Sync status with patient presence
    bedStatus = currentPatient != null ? BedStatus.OCCUPIED : BedStatus.AVAILABLE;
    return {
      'bedId': bedId,
      'status': bedStatus.toString().split('.').last,
      'patient': currentPatient?.toJson(),
    };
  }

  factory Bed.fromJson(Map<String, dynamic> json) {
    var bed = Bed(
      bedId: json['bedId'],
      bedStatus: BedStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => BedStatus.AVAILABLE,
      ),
    );
    if (json['patient'] != null) {
      bed.currentPatient = PatientInfo.fromJson(json['patient']);
      bed.bedStatus = BedStatus.OCCUPIED;
    } else {
      bed.bedStatus = BedStatus.AVAILABLE;
    }
    return bed;
  }
}
