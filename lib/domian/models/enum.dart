// Room types for hospital
enum RoomType {
  GENERAL_ROOM,
  PRIVATE_ROOM,
  ICU_ROOM,
  EMERGENCY_ROOM,
  OPERATING_ROOM,
}

// Bed status
enum BedStatus {
  OCCUPIED,
  AVAILABLE
}

// Patient gender
enum PatientGender {
  MALE,
  FEMALE
}

// Patient condition
enum PatientCondition {
  STABLE,
  EMERGENCY,
  CRITICAL,
  NEED_SURGERY,
  RECOVERED
}
