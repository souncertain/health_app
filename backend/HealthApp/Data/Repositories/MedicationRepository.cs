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

        public override async Task<List<Medication>> GetAll(CancellationToken ct = default)
        {
            return await Query(asNoTracking: true)
                .Include(x => x.DailyStatuses)
                .ToListAsync(ct);
        }

        public override async Task<Medication?> GetById(Guid id, CancellationToken ct = default)
        {
            return await Query(asNoTracking: true)
                .Include(x => x.DailyStatuses)
                .FirstOrDefaultAsync(x => x.Id == id, ct);
        }

        public async Task<IEnumerable<MedicationSoonestNotificationDto>> GetSoonestNotification()
        {
            var now = DateTime.Now;
            var medications = await Query(asNoTracking: true)
                .Include(x => x.DailyStatuses)
                .ToListAsync();

            return medications
                .Where(x => x.NotificationsEnabled)
                .Select(x => new
                {
                    Medication = x,
                    NextScheduledAt = GetNextScheduledAt(x, now)
                })
                .Where(x => x.NextScheduledAt is not null)
                .OrderBy(x => x.NextScheduledAt)
                .Select(x => new MedicationSoonestNotificationDto
                {
                    Name = x.Medication.Name,
                    DosageValue = x.Medication.DosageValue,
                    DosageUnit = x.Medication.DosageUnit,
                    ScheduledAt = x.NextScheduledAt!.Value,
                    SoonestNotificationTime = TimeOnly.FromDateTime(x.NextScheduledAt.Value),
                })
                .ToList();
        }

        public async Task<MedicationStatusesDto> GetMedicationStatuses()
        {
            var now = DateTime.Now;
            var today = DateOnly.FromDateTime(now);
            var currentTimeInMinutes = now.Hour * 60 + now.Minute;

            var medications = await Query(asNoTracking: true)
                .Select(x => new
                {
                    x.CreatedAt,
                    x.Frequency,
                    x.ScheduledWeekdays,
                    x.TimesInMinutes,
                    ExplicitStatus = x.DailyStatuses
                        .Where(status => status.Date == today)
                        .Select(status => (MedicationDayStatus?)status.Status)
                        .FirstOrDefault(),
                })
                .ToListAsync();

            var result = new MedicationStatusesDto();
            foreach (var medication in medications
                .Where(x => IsScheduledForDate(x.CreatedAt, x.Frequency, x.ScheduledWeekdays, today)))
            {
                var availableTimes = GetAvailableTimesForDate(
                    medication.CreatedAt,
                    medication.TimesInMinutes,
                    today);
                if (availableTimes.Count == 0)
                {
                    continue;
                }

                var status = ResolveStatusForToday(availableTimes, medication.ExplicitStatus, currentTimeInMinutes);
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

        public async Task<MedicationDailyStatus?> SetMedicationDailyStatus(
            Guid medicationId,
            DateOnly date,
            MedicationDayStatus? status,
            CancellationToken ct = default)
        {
            var medicationExists = await Query()
                .AnyAsync(x => x.Id == medicationId, ct);
            if (!medicationExists)
            {
                throw new InvalidOperationException($"Medication with id '{medicationId}' was not found.");
            }

            var existingStatus = await _context.Set<MedicationDailyStatus>()
                .FirstOrDefaultAsync(
                    x => x.MedicationId == medicationId && x.Date == date,
                    ct);

            if (status is null or MedicationDayStatus.Pending)
            {
                if (existingStatus is not null)
                {
                    _context.Set<MedicationDailyStatus>().Remove(existingStatus);
                    await _context.SaveChangesAsync(ct);
                }

                return null;
            }

            if (existingStatus is null)
            {
                existingStatus = new MedicationDailyStatus
                {
                    Id = Guid.NewGuid(),
                    MedicationId = medicationId,
                    Date = date,
                    Status = status.Value,
                    CreatedAt = DateTime.UtcNow,
                    LastUpdatedAt = DateTime.UtcNow,
                };
                _context.Set<MedicationDailyStatus>().Add(existingStatus);
            }
            else
            {
                existingStatus.Status = status.Value;
                existingStatus.LastUpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync(ct);
            return existingStatus;
        }

        private bool IsScheduledForDate(
            DateTime createdAt,
            MedicationFrequency frequency,
            List<int> scheduledWeekdays,
            DateOnly date)
        {
            var localCreatedAt = ToLocalTime(createdAt);
            var createdDate = DateOnly.FromDateTime(localCreatedAt);
            if (date < createdDate)
            {
                return false;
            }

            if (frequency == MedicationFrequency.DayAfterDay)
            {
                return createdDate.DayNumber % 2 == date.DayNumber % 2;
            }

            var isoWeekday = Medication.ToIsoWeekday(date.DayOfWeek);
            return scheduledWeekdays.Contains(isoWeekday);
        }

        private List<int> GetAvailableTimesForDate(
            DateTime createdAt,
            List<int> timesInMinutes,
            DateOnly date)
        {
            var localCreatedAt = ToLocalTime(createdAt);
            var availableTimes = timesInMinutes
                .OrderBy(x => x)
                .ToList();

            if (availableTimes.Count == 0)
            {
                return availableTimes;
            }

            if (DateOnly.FromDateTime(localCreatedAt) != date)
            {
                return availableTimes;
            }

            var createdMinutes = localCreatedAt.Hour * 60 + localCreatedAt.Minute;
            return availableTimes
                .Where(time => time >= createdMinutes)
                .ToList();
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

        private DateTime? GetNextScheduledAt(Medication medication, DateTime now)
        {
            var normalizedNow = now.Kind == DateTimeKind.Local ? now : now.ToLocalTime();
            var startDate = DateOnly.FromDateTime(normalizedNow);

            for (var offset = 0; offset <= 14; offset++)
            {
                var candidateDate = startDate.AddDays(offset);
                if (!IsScheduledForDate(
                    medication.CreatedAt,
                    medication.Frequency,
                    medication.ScheduledWeekdays,
                    candidateDate))
                {
                    continue;
                }

                var explicitStatus = medication.DailyStatuses
                    .FirstOrDefault(x => x.Date == candidateDate)
                    ?.Status;
                if (explicitStatus is MedicationDayStatus.Taken or MedicationDayStatus.Missed)
                {
                    continue;
                }

                var availableTimes = GetAvailableTimesForDate(
                    medication.CreatedAt,
                    medication.TimesInMinutes,
                    candidateDate);

                foreach (var time in availableTimes)
                {
                    var scheduledAt = new DateTime(
                        candidateDate.Year,
                        candidateDate.Month,
                        candidateDate.Day,
                        time / 60,
                        time % 60,
                        0,
                        DateTimeKind.Local);

                    if (scheduledAt > normalizedNow)
                    {
                        return scheduledAt;
                    }
                }
            }

            return null;
        }

        private DateTime ToLocalTime(DateTime value)
        {
            return value.Kind switch
            {
                DateTimeKind.Utc => value.ToLocalTime(),
                DateTimeKind.Unspecified => DateTime.SpecifyKind(value, DateTimeKind.Utc).ToLocalTime(),
                _ => value
            };
        }
    }
}
