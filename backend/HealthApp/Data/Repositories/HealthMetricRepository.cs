using Data.Interfaces;
using Domain.Dto.HealthMetric;
using Domain.Dto.MetricRecords;
using Domain.Entity;
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
    }
}
