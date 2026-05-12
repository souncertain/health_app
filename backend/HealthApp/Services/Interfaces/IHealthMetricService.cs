using Domain.Dto.HealthMetric;
using Domain.Entity;
using Enums;

namespace Services.Interfaces
{
    public interface IHealthMetricService : IAbstractService<HealthMetric, HealthMetricCreateDto, HealthMetricDetailsDto>
    {
        Task<HealthMetricDetailsDto> AddRecordToHealthMetric(Guid metricRecordId, Guid metricId);
        Task<MetricTrend> GetMetricTrend(Guid metricId);
    }
}
