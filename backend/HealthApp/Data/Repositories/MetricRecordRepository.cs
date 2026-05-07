using Data.Interfaces;
using Domain.Dto.MetricRecords;
using Domain.Entity;
using Microsoft.EntityFrameworkCore;

namespace Data.Repositories
{
    public class MetricRecordRepository : AbstractRepository<MetricRecord>, IMetricRecordRepository
    {
        public MetricRecordRepository(HealthAppDbContext context) : base(context)
        {
        }

        public async Task<IEnumerable<MetricRecordGraphProjection>> GetMetricRecordGraphProjections()
        {
            var list = await _context.Set<MetricRecord>()
                .Where(x => x.RecordedOn >= DateTime.UtcNow.AddDays(-7))
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
