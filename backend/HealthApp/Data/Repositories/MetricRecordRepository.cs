using Data.Interfaces;
using Domain.Dto.MetricRecords;
using Domain.Entity;
using Microsoft.EntityFrameworkCore;

namespace Data.Repositories
{
    public class MetricRecordRepository : AbstractRepository<MetricRecord>, IMetricRecordRepository
    {
        public MetricRecordRepository(HealthAppDbContext context, ICurrentUserContext currentUserContext)
            : base(context, currentUserContext)
        {
        }

        public async Task<IEnumerable<MetricRecordGraphProjection>> GetMetricRecordGraphProjections()
        {
            var scopedMetricIds = ApplyCurrentUserScope(_context.Set<HealthMetric>().AsNoTracking())
                .Select(x => x.Id);

            var list = await _context.Set<MetricRecord>()
                .AsNoTracking()
                .Where(x => scopedMetricIds.Contains(x.HealthMetricId))
                .Where(x => x.RecordedOn >= DateTime.UtcNow.Date.AddDays(-7))
                .Select(x => new MetricRecordGraphProjection
                {
                    RecordedAt = x.RecordedOn,
                    Value = (int)x.Value
                })
                .ToListAsync();
            return list;
        }
    }
}
