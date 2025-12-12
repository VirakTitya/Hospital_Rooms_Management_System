import 'package:room_management/domian/models/enum.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid().v4();

// Patient info model
class PatientInfo {
  final String patientId;
  final String name;
  final PatientGender gender;
  final DateTime entryDate;
  DateTime? leaveDate;
  PatientCondition condition;
  bool wantsPrivateRoom;

  String? currentBedId;
  List<String> bedHistory = [];
  List<String> statusHistory = [];

  PatientInfo({
    String? patientId,
    required this.name,
    required this.gender,
    required this.entryDate,
    required this.condition,
    this.wantsPrivateRoom = false,
    this.leaveDate,
  }) : patientId = patientId ?? uuid;

  // Assign bed to patient
  void assignBed(String bedId) {
    currentBedId = bedId;
    bedHistory.add(bedId);
  }

  // Release bed from patient
  void releaseBed() => currentBedId = null;

  Map<String, dynamic> toJson() => {
    'patientId': patientId,
    'name': name,
    'gender': gender.toString().split('.').last,
    'entryDate': entryDate.toIso8601String(),
    'leaveDate': leaveDate?.toIso8601String(),
    'condition': condition.toString().split('.').last,
    'wantsPrivateRoom': wantsPrivateRoom,
    'currentBedId': currentBedId,
    'bedHistory': bedHistory,
    'statusHistory': statusHistory,
  };

  // Factory for creating from JSON
  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    var patient = PatientInfo(
      patientId: json['patientId'],
      name: json['name'],
      gender: PatientGender.values.firstWhere(
        (e) => e.toString().split('.').last == json['gender'],
        orElse: () => throw FormatException('Invalid gender: ${json['gender']}'),
      ),
      entryDate: DateTime.parse(json['entryDate']),
      leaveDate: json['leaveDate'] != null
          ? DateTime.parse(json['leaveDate'])
          : null,
      condition: PatientCondition.values.firstWhere(
        (e) => e.toString().split('.').last == json['condition'],
        orElse: () =>
            throw FormatException('Invalid condition: ${json['condition']}'),
      ),
      wantsPrivateRoom: json['wantsPrivateRoom'] ?? json['requestPrivateRoom'] ?? false,
    );
    patient.currentBedId = json['currentBedId'] ?? json['currentBed'];
    patient.bedHistory = List<String>.from(json['bedHistory'] ?? []);
    patient.statusHistory = List<String>.from(json['statusHistory'] ?? json['history'] ?? []);
    return patient;
  }

  @override
  String toString() => 'PatientInfo: $name (ID: $patientId)';
}
