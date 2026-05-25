using Domain.Dto.Medication;
using Domain.Entity;
using Enums;

namespace Services.Interfaces
{
    public interface IMedicationService : IAbstractService<Medication, MedicationCreateDto, MedicationDetailsDto>
    {
        Task<IEnumerable<MedicationSoonestNotificationDto>> GetSoonestNotification();
        Task<MedicationStatusesDto> GetMedicationStatuses();
        Task<MedicationDailyStatusDetailsDto?> SetMedicationDailyStatus(
            Guid medicationId,
            DateOnly date,
            MedicationDayStatus? status,
            CancellationToken ct = default);
    }
}
