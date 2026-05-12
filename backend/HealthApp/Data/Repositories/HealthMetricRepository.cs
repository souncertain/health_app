using Data.Interfaces;
using Domain.Entity;
using Enums;
using Microsoft.EntityFrameworkCore;

namespace Data.Repositories
{
    public class HealthMetricRepository : AbstractRepository<HealthMetric>, IHealthMetricRepository
    {
        public HealthMetricRepository(HealthAppDbContext context) : base(context)
        {
        }
        public async Task<HealthMetric> AddRecordToHealthMetric(Guid metricRecordId, Guid metricId)
        {
            var healthMetric = await _context.Set<HealthMetric>().Where(x => x.Id == metricId).FirstOrDefaultAsync();
            var metricRecord = await _context.Set<MetricRecord>().Where(x => x.Id == metricRecordId).FirstOrDefaultAsync();
            if (healthMetric is null || metricRecord is null) throw new ArgumentNullException("No health metric or metric record with this id");
            healthMetric.Records.Add(metricRecord);
            return healthMetric;
        }
        public async Task<MetricTrend> GetMetricTrend(Guid metricId)
        {
            var values = await _context.Set<MetricRecord>()
                .Where(x => x.Id == metricId)
                .OrderByDescending(x => x.RecordedOn)
                .Select(x => x.Value)
                .Take(2)
                .ToListAsync();

            if (values.Count < 2)
            {
                return MetricTrend.None;
            }

            var last = values[0];
            var previous = values[1];

            var delta = last - previous;

            if (Math.Abs(delta) < 0.01)
            {
                return MetricTrend.Stable;
            }

            return delta < 0
                ? MetricTrend.Down
                : MetricTrend.Up;
        }
    }
}
