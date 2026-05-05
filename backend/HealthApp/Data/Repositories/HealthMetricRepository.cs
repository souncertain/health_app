using Data.Interfaces;
using Domain.Entity;

namespace Data.Repositories
{
    public class HealthMetricRepository : AbstractRepository<HealthMetric>, IHealthMetricRepository
    {
        public HealthMetricRepository(HealthAppDbContext context) : base(context)
        {
        }
    }
}
