using AutoMapper;
using Data.Interfaces;
using Domain.Dto.MetricRecords;
using Domain.Entity;
using Services.Interfaces;

namespace Services.Services
{
    public class MetricRecordService : AbstractService<MetricRecord, MetricRecordCreateDto, MetricRecordDetailsDto>, IMetricRecordService
    {
        private readonly IMetricRecordRepository _metricRecordRepository;
        public MetricRecordService(IMetricRecordRepository repository, IMapper mapper) : base(repository, mapper)
        {
            _metricRecordRepository = repository;
        }

        public async Task<IEnumerable<MetricRecordGraphProjection>> GetMetricRecordGraphProjections()
        {
            return await _metricRecordRepository.GetMetricRecordGraphProjections();
        }
    }
}
