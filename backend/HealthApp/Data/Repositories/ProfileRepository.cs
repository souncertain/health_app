using Data.Interfaces;
using Domain.Dto.Profile;
using Domain.Entity;
using Microsoft.EntityFrameworkCore;

namespace Data.Repositories
{
    public class ProfileRepository : AbstractRepository<Profile>, IProfileRepository
    {
        public ProfileRepository(HealthAppDbContext context, ICurrentUserContext currentUserContext)
            : base(context, currentUserContext)
        {
        }

        public async Task<Profile?> GetCurrentProfile(CancellationToken ct = default)
        {
            var scopedUserId = await ResolveScopedUserId(ct);
            var query = _context.Set<Profile>().AsQueryable();
            if (scopedUserId.HasValue)
            {
                query = query.Where(x => x.UserId == scopedUserId.Value);
            }

            return await query
                .Include(x => x.User)
                .OrderBy(x => x.CreatedAt)
                .FirstOrDefaultAsync(ct);
        }

        public async Task<User?> GetCurrentUser(CancellationToken ct = default)
        {
            var scopedUserId = await ResolveScopedUserId(ct);
            IQueryable<User> query = _context.Set<User>();
            if (scopedUserId.HasValue)
            {
                query = query.Where(x => x.Id == scopedUserId.Value);
            }

            return await query
                .Include(x => x.Profile)
                .OrderBy(x => x.CreatedAt)
                .FirstOrDefaultAsync(ct);
        }

        public async Task<ProfileStatsDto> GetCurrentProfileStats(CancellationToken ct = default)
        {
            var scopedUserId = await ResolveScopedUserId(ct);

            var bloodPressureQuery = _context.Set<BloodPressure>().AsNoTracking().AsQueryable();
            var medicationQuery = _context.Set<Medication>().AsNoTracking().AsQueryable();
            var visitQuery = _context.Set<MedicalVisit>().AsNoTracking().AsQueryable();
            var healthMetricQuery = _context.Set<HealthMetric>().AsNoTracking().AsQueryable();

            if (scopedUserId.HasValue)
            {
                bloodPressureQuery = bloodPressureQuery.Where(x => x.UserId == scopedUserId.Value);
                medicationQuery = medicationQuery.Where(x => x.UserId == scopedUserId.Value);
                visitQuery = visitQuery.Where(x => x.UserId == scopedUserId.Value);
                healthMetricQuery = healthMetricQuery.Where(x => x.UserId == scopedUserId.Value);
            }

            var scopedHealthMetricIds = healthMetricQuery.Select(x => x.Id);

            var bloodPressureReadingsCount = await bloodPressureQuery.CountAsync(ct);
            var medicationsCount = await medicationQuery.CountAsync(ct);
            var appointmentsCount = await visitQuery.CountAsync(ct);

            var bloodPressureTrackedAt = await bloodPressureQuery
                .Select(x => (DateTime?)x.RecordedAt)
                .MinAsync(ct);
            var medicationTrackedAt = await medicationQuery
                .Select(x => (DateTime?)x.CreatedAt)
                .MinAsync(ct);
            var visitsTrackedAt = await visitQuery
                .Select(x => (DateTime?)x.CreatedAt)
                .MinAsync(ct);
            var metricsTrackedAt = await _context.Set<MetricRecord>()
                .AsNoTracking()
                .Where(x => scopedHealthMetricIds.Contains(x.HealthMetricId))
                .Select(x => (DateTime?)x.RecordedOn)
                .MinAsync(ct);

            var trackedDates = new[]
            {
                bloodPressureTrackedAt,
                medicationTrackedAt,
                visitsTrackedAt,
                metricsTrackedAt,
            }
            .Where(x => x.HasValue)
            .Select(x => x!.Value.Date)
            .ToList();

            var daysTracked = trackedDates.Count == 0
                ? 0
                : (DateTime.UtcNow.Date - trackedDates.Min()).Days + 1;

            return new ProfileStatsDto
            {
                BloodPressureReadingsCount = bloodPressureReadingsCount,
                MedicationsCount = medicationsCount,
                AppointmentsCount = appointmentsCount,
                DaysTracked = daysTracked,
            };
        }

        private async Task<Guid?> ResolveScopedUserId(CancellationToken ct)
        {
            if (CurrentUserId.HasValue)
            {
                return CurrentUserId.Value;
            }

            return await _context.Set<User>()
                .AsNoTracking()
                .OrderBy(x => x.CreatedAt)
                .Select(x => (Guid?)x.Id)
                .FirstOrDefaultAsync(ct);
        }
    }
}
