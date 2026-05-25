using Domain.Dto.Medication;
using Domain.Entity;
using Enums;

namespace Data.Interfaces
{
    public interface IMedicationRepository : IAbstractRepository<Medication>
    {
        Task<IEnumerable<MedicationSoonestNotificationDto>> GetSoonestNotification();
        Task<MedicationStatusesDto> GetMedicationStatuses();
        Task<MedicationDailyStatus?> SetMedicationDailyStatus(
            Guid medicationId,
            DateOnly date,
            MedicationDayStatus? status,
            CancellationToken ct = default);
    }
}
