import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../../../core/network/authenticated_api_client.dart';
import '../../domain/entities/doctor_note_scan_result.dart';

class DoctorNoteScannerRemoteDataSource {
  DoctorNoteScannerRemoteDataSource({
    AuthenticatedApiClient? apiClient,
  }) : _apiClient = apiClient ?? AuthenticatedApiClient();

  final AuthenticatedApiClient _apiClient;

  Future<DoctorNoteScanResult> analyzeImage(XFile image) async {
    final bytes = await image.readAsBytes();
    final response = await _apiClient.postMultipart(
      '/api/doctor-note-scanner/analyze',
      files: [
        ApiMultipartFile(
          fieldName: 'image',
          fileName: image.name,
          contentType: _detectContentType(image, bytes),
          bytes: bytes,
        ),
      ],
    );

    return _parseResult(response as Map<String, dynamic>);
  }

  DoctorNoteScanResult _parseResult(Map<String, dynamic> json) {
    return DoctorNoteScanResult(
      category: _parseCategory(json['category'] as String?),
      rawText: (json['rawText'] as String? ?? '').trim(),
      summary: (json['summary'] as String? ?? '').trim(),
      warnings:
          (json['warnings'] as List<dynamic>? ?? const [])
              .map((item) => '$item'.trim())
              .where((item) => item.isNotEmpty)
              .toList(),
      medications:
          (json['medications'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(
                (item) => DoctorNoteMedicationCandidate(
                  name: (item['name'] as String? ?? '').trim(),
                  dosageText: (item['dosageText'] as String? ?? '').trim(),
                  frequencyText: (item['frequencyText'] as String? ?? '').trim(),
                  instructions: (item['instructions'] as String? ?? '').trim(),
                  note: (item['note'] as String? ?? '').trim(),
                ),
              )
              .toList(),
      visits:
          (json['visits'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(
                (item) => DoctorNoteVisitCandidate(
                  doctorName: (item['doctorName'] as String? ?? '').trim(),
                  specialty: (item['specialty'] as String? ?? '').trim(),
                  dateText: (item['dateText'] as String? ?? '').trim(),
                  timeText: (item['timeText'] as String? ?? '').trim(),
                  location: (item['location'] as String? ?? '').trim(),
                  note: (item['note'] as String? ?? '').trim(),
                ),
              )
              .toList(),
    );
  }

  DoctorNoteCategory _parseCategory(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'medication':
        return DoctorNoteCategory.medication;
      case 'medical_visit':
        return DoctorNoteCategory.medicalVisit;
      case 'mixed':
        return DoctorNoteCategory.mixed;
      default:
        return DoctorNoteCategory.unknown;
    }
  }

  String _detectContentType(XFile image, Uint8List bytes) {
    final extension = image.name.toLowerCase();
    if (extension.endsWith('.png')) {
      return 'image/png';
    }
    if (extension.endsWith('.webp')) {
      return 'image/webp';
    }
    if (extension.endsWith('.heic')) {
      return 'image/heic';
    }
    if (extension.endsWith('.heif')) {
      return 'image/heif';
    }

    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }

    return 'image/jpeg';
  }
}
