using Domain.Entity;

namespace Data.Interfaces
{
    public interface IHealthMetricRepository : IAbstractRepository<HealthMetric>
    {
        Task<HealthMetric> AddRecordToHealthMetric(Guid metricRecordId, Guid metricId);
    }
}
