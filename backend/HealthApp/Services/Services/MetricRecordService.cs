using AutoMapper;
using Data.Interfaces;
using Domain.Dto.MetricRecords;
using Domain.Entity;
using Services.Interfaces;
using Services.Validation.Infrastructure;

namespace Services.Services
{
    public class MetricRecordService : AbstractService<MetricRecord, MetricRecordCreateDto, MetricRecordDetailsDto>, IMetricRecordService
    {
        private readonly IMetricRecordRepository _metricRecordRepository;

        public MetricRecordService(
            IMetricRecordRepository repository,
            IMapper mapper,
            IRequestValidationService validationService) : base(repository, mapper, validationService)
        {
            _metricRecordRepository = repository;
        }

        public async Task<IEnumerable<MetricRecordGraphProjection>> GetMetricRecordGraphProjections()
        {
            return await _metricRecordRepository.GetMetricRecordGraphProjections();
        }
    }
}
