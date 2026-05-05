using AutoMapper;
using Data.Interfaces;
using Domain.Dto.HealthMetric;
using Domain.Entity;
using Services.Interfaces;

namespace Services.Services
{
    public class HealthMetricService : AbstractService<HealthMetric, HealthMetricCreateDto, HealthMetricDetailsDto>, IHealthMetricService
    {
        public HealthMetricService(IHealthMetricRepository repository, IMapper mapper) : base(repository, mapper) { }
    }
}
