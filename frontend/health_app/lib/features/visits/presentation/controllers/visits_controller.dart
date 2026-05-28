import '../../../../core/controllers/cache_first_collection_controller.dart';
import '../../../../core/services/local_notifications_service.dart';
import '../../../../core/utils/collection_extensions.dart';
import '../../domain/entities/medical_visit.dart';
import '../../domain/usecases/delete_medical_visit.dart';
import '../../domain/usecases/get_cached_medical_visits.dart';
import '../../domain/usecases/get_medical_visits.dart';
import '../../domain/usecases/save_medical_visit.dart';

class VisitsController extends CacheFirstCollectionController<MedicalVisit> {
  VisitsController({
    required GetCachedMedicalVisitsUseCase getCachedVisits,
    required GetMedicalVisitsUseCase getVisits,
    required SaveMedicalVisitUseCase saveVisit,
    required DeleteMedicalVisitUseCase deleteVisit,
    NotificationScheduler? notificationScheduler,
  }) : _getCachedVisits = getCachedVisits,
       _getVisits = getVisits,
       _saveVisit = saveVisit,
       _deleteVisit = deleteVisit,
       _notificationScheduler =
           notificationScheduler ?? LocalNotificationsService.instance;

  final GetCachedMedicalVisitsUseCase _getCachedVisits;
  final GetMedicalVisitsUseCase _getVisits;
  final SaveMedicalVisitUseCase _saveVisit;
  final DeleteMedicalVisitUseCase _deleteVisit;
  final NotificationScheduler _notificationScheduler;

  List<MedicalVisit> get visits => List.unmodifiable(currentItems);

  @override
  String get refreshErrorMessage =>
      'Р СњР Вµ РЎС“Р Т‘Р В°Р В»Р С•РЎРѓРЎРЉ Р В·Р В°Р С–РЎР‚РЎС“Р В·Р С‘РЎвЂљРЎРЉ Р Р†Р С‘Р В·Р С‘РЎвЂљРЎвЂ№.';

  @override
  Future<List<MedicalVisit>> loadCachedItems() => _getCachedVisits();

  @override
  Future<List<MedicalVisit>> loadRemoteItems() => _getVisits();

  @override
  List<MedicalVisit> sortItems(List<MedicalVisit> items) {
    final sorted = List<MedicalVisit>.from(items)
      ..sort((left, right) => left.scheduledAt.compareTo(right.scheduledAt));
    return sorted;
  }

  @override
  Future<void> onItemsUpdated(List<MedicalVisit> items) {
    return _notificationScheduler.syncVisitNotifications(items);
  }

  List<MedicalVisit> visitsForType(MedicalVisitType type) {
    final filtered = currentItems
        .where((visit) => visit.visitType == type)
        .toList();
    filtered.sort(
      (left, right) => left.scheduledAt.compareTo(right.scheduledAt),
    );
    return filtered;
  }

  MedicalVisit? nextVisitForType(MedicalVisitType type) {
    final now = DateTime.now();
    final filtered = visitsForType(type);

    for (final visit in filtered) {
      if (!visit.scheduledAt.isBefore(now)) {
        return visit;
      }
    }

    return filtered.isEmpty ? null : filtered.first;
  }

  Future<void> saveVisit({
    MedicalVisit? existingVisit,
    required String doctorName,
    required String specialty,
    required DateTime appointmentDate,
    required int timeInMinutes,
    required String location,
    required MedicalVisitType visitType,
  }) async {
    final now = DateTime.now();
    final visit =
        existingVisit?.copyWith(
          doctorName: doctorName,
          specialty: specialty,
          appointmentDate: MedicalVisit.normalizeDate(appointmentDate),
          timeInMinutes: timeInMinutes,
          location: location,
          visitType: visitType,
          updatedAt: now,
        ) ??
        MedicalVisit(
          id: 'visit-${now.microsecondsSinceEpoch}',
          doctorName: doctorName,
          specialty: specialty,
          appointmentDate: MedicalVisit.normalizeDate(appointmentDate),
          timeInMinutes: timeInMinutes,
          location: location,
          visitType: visitType,
          rating: visitType == MedicalVisitType.oneTime ? 4.9 : 4.8,
          createdAt: now,
          updatedAt: now,
        );

    await runOptimisticMutation(
      nextItems: _upsertVisit(currentItems, visit),
      action: () => _saveVisit(visit),
      errorMessage:
          'Р СњР Вµ РЎС“Р Т‘Р В°Р В»Р С•РЎРѓРЎРЉ РЎРѓР С•РЎвЂ¦РЎР‚Р В°Р Р…Р С‘РЎвЂљРЎРЉ Р Р†Р С‘Р В·Р С‘РЎвЂљ.',
      rethrowOnFailure: true,
    );
  }

  Future<void> rescheduleVisit(MedicalVisit visit, int timeInMinutes) async {
    final updatedVisit = visit.copyWith(
      timeInMinutes: timeInMinutes,
      updatedAt: DateTime.now(),
    );
    await runOptimisticMutation(
      nextItems: _upsertVisit(currentItems, updatedVisit),
      action: () => _saveVisit(updatedVisit),
      errorMessage:
          'Р СњР Вµ РЎС“Р Т‘Р В°Р В»Р С•РЎРѓРЎРЉ Р С—Р ВµРЎР‚Р ВµР Р…Р ВµРЎРѓРЎвЂљР С‘ Р Р†Р С‘Р В·Р С‘РЎвЂљ.',
      rethrowOnFailure: true,
    );
  }

  Future<void> deleteVisit(MedicalVisit visit) async {
    await runOptimisticMutation(
      nextItems: currentItems.where((item) => item.id != visit.id).toList(),
      action: () async {
        await _deleteVisit(visit.id);
        await _notificationScheduler.cancelVisitNotification(visit.id);
      },
      errorMessage:
          'Р СњР Вµ РЎС“Р Т‘Р В°Р В»Р С•РЎРѓРЎРЉ РЎС“Р Т‘Р В°Р В»Р С‘РЎвЂљРЎРЉ Р Р†Р С‘Р В·Р С‘РЎвЂљ.',
      rethrowOnFailure: true,
    );
  }

  List<MedicalVisit> _upsertVisit(
    List<MedicalVisit> source,
    MedicalVisit visit,
  ) {
    final updated = List<MedicalVisit>.from(source);
    updated.upsertWhere(visit, (item) => item.id == visit.id);
    updated.sort((left, right) => left.scheduledAt.compareTo(right.scheduledAt));
    return updated;
  }
}
