using AutoMapper;
using Data.Interfaces;
using Domain.Dto.MetricRecords;
using Domain.Entity;
using Services.Interfaces;

namespace Services.Services
{
    public class MetricRecordService : AbstractService<MetricRecord, MetricRecordCreateDto, MetricRecordDetailsDto>, IMetricRecordService
    {
        public MetricRecordService(IMetricRecordRepository repository, IMapper mapper) : base(repository, mapper) { }
    }
}
