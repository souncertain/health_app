using Domain.Dto.HealthMetric;
using Domain.Entity;

namespace Services.Interfaces
{
    public interface IHealthMetricService : IAbstractService<HealthMetric, HealthMetricCreateDto, HealthMetricDetailsDto>
    {
    }
}
