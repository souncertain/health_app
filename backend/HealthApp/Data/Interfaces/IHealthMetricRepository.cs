using Domain.Entity;
using Enums;

namespace Data.Interfaces
{
    public interface IHealthMetricRepository : IAbstractRepository<HealthMetric>
    {
        Task<HealthMetric> AddRecordToHealthMetric(Guid metricRecordId, Guid metricId);
        Task<MetricTrend> GetMetricTrend(Guid metricId);
    }
}
