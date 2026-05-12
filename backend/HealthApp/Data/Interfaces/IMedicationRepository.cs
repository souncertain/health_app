using Domain.Dto.Medication;
using Domain.Entity;

namespace Data.Interfaces
{
    public interface IMedicationRepository : IAbstractRepository<Medication>
    {
        //Task ToggleNotify(Guid medicationId);
        //TODO: Придумать, как реализовать это, возможно использовать метод base репозитория update
        Task<IEnumerable<MedicationSoonestNotificationDto>> GetSoonestNotification();
        Task<MedicationStatusesDto> GetMedicationStatuses();
    }
}
