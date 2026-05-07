using Domain.Dto.MetricRecords;
using Domain.Entity;

namespace Data.Interfaces
{
    public interface IMetricRecordRepository : IAbstractRepository<MetricRecord>
    {
        Task<IEnumerable<MetricRecordGraphProjection>> GetMetricRecordGraphProjections();
    }
}
