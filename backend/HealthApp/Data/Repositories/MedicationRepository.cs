using Data.Interfaces;
using Domain.Dto.Medication;
using Domain.Entity;
using Microsoft.EntityFrameworkCore;

namespace Data.Repositories
{
    public class MedicationRepository : AbstractRepository<Medication>, IMedicationRepository
    {
        public MedicationRepository(HealthAppDbContext context) : base(context)
        {
        }
        public async Task<IEnumerable<MedicationSoonestNotificationDto>> GetSoonestNotification()
        {
            var time = TimeOnly.FromDateTime(DateTime.UtcNow);
            var currentTimeInMinutes = time.Minute + time.Hour * 60;
            var medications = await _context.Set<Medication>()
                .Where(x => x.NotificationsEnabled && x.TimesInMinutes.Any(x => x >= currentTimeInMinutes)) // TODO Only today
                .ToListAsync();
            return medications.Select(x => new MedicationSoonestNotificationDto()
            {
                Name = x.Name,
                SoonestNotificationTime = GetFirstTimeFromMedication(x.TimesInMinutes, currentTimeInMinutes),
                DosageUnit = x.DosageUnit,
                DosageValue = x.DosageValue,
            });
        }
        public Task<MedicationStatusesDto> GetMedicationStatuses()
        {
            throw new NotImplementedException();
        }
        private TimeOnly GetFirstTimeFromMedication(List<int> timesInMinutes, int currentTimeInMinutes)
        {
            var firstTimeInMinutes = timesInMinutes.First(x => x >= currentTimeInMinutes);
            int hours = firstTimeInMinutes / 60;
            int minutes = firstTimeInMinutes % 60;
            return new TimeOnly(hours, minutes);
        }
    }
}
