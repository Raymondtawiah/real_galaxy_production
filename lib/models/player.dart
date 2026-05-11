import 'package:flutter/foundation.dart';

enum PlayerStatus { active, injured, suspended }

enum HealthStatus { fit, minorInjury, injured, recovering, notFit }

class Player {
  final String? id;
  final String name;
  final int age;
  final DateTime? dateOfBirth;
  final String gender;
  final String? position;
  final String? teamId;
  final String parentId;
  final PlayerStatus status;
  final HealthStatus healthStatus;
  final String? injuryDetails;
  final bool medicalClearance;
  final String? doctorNotes;
  final String? recoveryPlan;
  final DateTime? lastMedicalCheck;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? imageUrl;
  final bool isActive;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Player({
    this.id,
    required this.name,
    required this.age,
    this.dateOfBirth,
    required this.gender,
    this.position,
    this.teamId,
    required this.parentId,
    this.status = PlayerStatus.active,
    this.healthStatus = HealthStatus.fit,
    this.injuryDetails,
    this.medicalClearance = true,
    this.doctorNotes,
    this.recoveryPlan,
    this.lastMedicalCheck,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.imageUrl,
    this.isActive = true,
    this.isDeleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'position': position,
      'team_id': teamId,
      'parent_id': parentId,
      'status': status.name,
      'health_status': healthStatus.name,
      'injury_details': injuryDetails,
      'medical_clearance': medicalClearance,
      'doctor_notes': doctorNotes,
      'recovery_plan': recoveryPlan,
      'last_medical_check': lastMedicalCheck?.toIso8601String(),
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'image_url': imageUrl,
      'is_active': isActive ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Player.fromMap(String id, Map<String, dynamic> map) {
    return Player(
      id: id,
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.tryParse(map['date_of_birth'])
          : null,
      gender: map['gender'] ?? '',
      position: map['position'],
      teamId: map['team_id'],
      parentId: map['parent_id'] ?? '',
      status: PlayerStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'active'),
        orElse: () => PlayerStatus.active,
      ),
      healthStatus: HealthStatus.values.firstWhere(
        (e) => e.name == (map['health_status'] ?? 'fit'),
        orElse: () => HealthStatus.fit,
      ),
      injuryDetails: map['injury_details'],
      medicalClearance:
          map['medical_clearance'] == true ||
          map['medical_clearance'] == 1 ||
          map['medical_clearance'] == '1',
      doctorNotes: map['doctor_notes'],
      recoveryPlan: map['recovery_plan'],
      lastMedicalCheck: map['last_medical_check'] != null
          ? DateTime.tryParse(map['last_medical_check'])
          : null,
      emergencyContactName: map['emergency_contact_name'],
      emergencyContactPhone: map['emergency_contact_phone'],
      imageUrl: map['image_url'],
      isActive: map['is_active'] == 1 ||
          map['is_active'] == true ||
          map['is_active'] == '1' ||
          map['is_active'] == null,
      isDeleted: map['is_deleted'] == 1 ||
          map['is_deleted'] == true ||
          map['is_deleted'] == '1' ||
          map['is_deleted'] == null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Player copyWith({
    String? id,
    String? name,
    int? age,
    DateTime? dateOfBirth,
    String? gender,
    String? position,
    String? teamId,
    String? parentId,
    PlayerStatus? status,
    HealthStatus? healthStatus,
    String? injuryDetails,
    bool? medicalClearance,
    String? doctorNotes,
    String? recoveryPlan,
    DateTime? lastMedicalCheck,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? imageUrl,
    bool? isActive,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      position: position ?? this.position,
      teamId: teamId ?? this.teamId,
      parentId: parentId ?? this.parentId,
      status: status ?? this.status,
      healthStatus: healthStatus ?? this.healthStatus,
      injuryDetails: injuryDetails ?? this.injuryDetails,
      medicalClearance: medicalClearance ?? this.medicalClearance,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      recoveryPlan: recoveryPlan ?? this.recoveryPlan,
      lastMedicalCheck: lastMedicalCheck ?? this.lastMedicalCheck,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

