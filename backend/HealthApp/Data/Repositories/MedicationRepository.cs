using Data.Interfaces;
using Domain.Dto.Medication;
using Domain.Entity;
using Enums;
using Microsoft.EntityFrameworkCore;

namespace Data.Repositories
{
    public class MedicationRepository : AbstractRepository<Medication>, IMedicationRepository
    {
        public MedicationRepository(HealthAppDbContext context, ICurrentUserContext currentUserContext)
            : base(context, currentUserContext)
        {
        }

        public async Task<IEnumerable<MedicationSoonestNotificationDto>> GetSoonestNotification()
        {
            var now = DateTime.UtcNow;
            var today = DateOnly.FromDateTime(now);
            var currentTimeInMinutes = now.Hour * 60 + now.Minute;
            var isoWeekday = Medication.ToIsoWeekday(now.DayOfWeek);

            var medications = await Query(asNoTracking: true)
                .Where(x => x.NotificationsEnabled && x.ScheduledWeekdays.Contains(isoWeekday))
                .Select(x => new
                {
                    x.Name,
                    x.DosageValue,
                    x.DosageUnit,
                    x.TimesInMinutes,
                    ExplicitStatus = x.DailyStatuses
                        .Where(status => status.Date == today)
                        .Select(status => (MedicationDayStatus?)status.Status)
                        .FirstOrDefault(),
                })
                .ToListAsync();

            return medications
                .Where(x => x.ExplicitStatus != MedicationDayStatus.Taken && x.ExplicitStatus != MedicationDayStatus.Missed)
                .Where(x => x.TimesInMinutes.Any(time => time >= currentTimeInMinutes))
                .Select(x => new MedicationSoonestNotificationDto()
                {
                    Name = x.Name,
                    SoonestNotificationTime = GetFirstTimeFromMedication(x.TimesInMinutes, currentTimeInMinutes),
                    DosageUnit = x.DosageUnit,
                    DosageValue = x.DosageValue,
                })
                .OrderBy(x => x.SoonestNotificationTime)
                .ToList();
        }

        public async Task<MedicationStatusesDto> GetMedicationStatuses()
        {
            var now = DateTime.UtcNow;
            var today = DateOnly.FromDateTime(now);
            var currentTimeInMinutes = now.Hour * 60 + now.Minute;
            var isoWeekday = Medication.ToIsoWeekday(now.DayOfWeek);

            var medications = await Query(asNoTracking: true)
                .Where(x => x.ScheduledWeekdays.Contains(isoWeekday))
                .Select(x => new
                {
                    x.TimesInMinutes,
                    ExplicitStatus = x.DailyStatuses
                        .Where(status => status.Date == today)
                        .Select(status => (MedicationDayStatus?)status.Status)
                        .FirstOrDefault(),
                })
                .ToListAsync();

            var result = new MedicationStatusesDto();
            foreach (var medication in medications)
            {
                var status = ResolveStatusForToday(medication.TimesInMinutes, medication.ExplicitStatus, currentTimeInMinutes);
                switch (status)
                {
                    case MedicationDayStatus.Taken:
                        result.TakenCount++;
                        break;
                    case MedicationDayStatus.Missed:
                        result.MissedCount++;
                        break;
                    default:
                        result.PendingCount++;
                        break;
                }
            }

            return result;
        }

        private TimeOnly GetFirstTimeFromMedication(List<int> timesInMinutes, int currentTimeInMinutes)
        {
            var firstTimeInMinutes = timesInMinutes.First(x => x >= currentTimeInMinutes);
            int hours = firstTimeInMinutes / 60;
            int minutes = firstTimeInMinutes % 60;
            return new TimeOnly(hours, minutes);
        }

        private MedicationDayStatus ResolveStatusForToday(
            List<int> timesInMinutes,
            MedicationDayStatus? explicitStatus,
            int currentTimeInMinutes)
        {
            if (explicitStatus is MedicationDayStatus.Taken or MedicationDayStatus.Missed)
            {
                return explicitStatus.Value;
            }

            if (timesInMinutes.Count == 0)
            {
                return MedicationDayStatus.Pending;
            }

            var lastScheduledTime = timesInMinutes.Max();
            return currentTimeInMinutes > lastScheduledTime
                ? MedicationDayStatus.Missed
                : MedicationDayStatus.Pending;
        }
    }
}
