using Domain.Dto.MetricRecords;
using Domain.Entity;

namespace Services.Interfaces
{
    public interface IMetricRecordService : IAbstractService<MetricRecord, MetricRecordCreateDto, MetricRecordDetailsDto>
    {
        Task<IEnumerable<MetricRecordGraphProjection>> GetMetricRecordGraphProjections();
    }
}
