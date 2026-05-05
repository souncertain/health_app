using Data.Interfaces;
using Domain.Entity;

namespace Data.Repositories
{
    public class MetricRecordRepository : AbstractRepository<MetricRecord>, IMetricRecordRepository
    {
        public MetricRecordRepository(HealthAppDbContext context) : base(context)
        {
        }
    }
}
