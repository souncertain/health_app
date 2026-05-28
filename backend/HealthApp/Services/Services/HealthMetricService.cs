using AutoMapper;
using Data.Interfaces;
using Domain.Dto.HealthMetric;
using Domain.Entity;
using Enums;
using Services.Interfaces;
using Services.Validation.Infrastructure;

namespace Services.Services
{
    public class HealthMetricService : AbstractService<HealthMetric, HealthMetricCreateDto, HealthMetricDetailsDto>, IHealthMetricService
    {
        private readonly IHealthMetricRepository _healthMetricRepository;

        public HealthMetricService(
            IHealthMetricRepository repository,
            IMapper mapper,
            IRequestValidationService validationService) : base(repository, mapper, validationService)
        {
            _healthMetricRepository = repository;
        }

        public async Task<HealthMetricDetailsDto> AddRecordToHealthMetric(Guid metricRecordId, Guid metricId)
        {
            var metric = await _healthMetricRepository.AddRecordToHealthMetric(metricRecordId, metricId);
            return _mapper.Map<HealthMetricDetailsDto>(metric);
        }

        public async Task<MetricTrend> GetMetricTrend(Guid metricId)
        {
            return await _healthMetricRepository.GetMetricTrend(metricId);
        }
    }
}
