using Domain.Dto.MetricRecords;
using Domain.Entity;
using Microsoft.AspNetCore.Mvc;
using Services.Interfaces;

namespace HealthApp.Controllers
{
    [ApiController]
    [Route("api/metricrecord")]
    public class MetricRecordController : AbstractController<MetricRecord, MetricRecordCreateDto, MetricRecordDetailsDto, IMetricRecordService>
    {
        public MetricRecordController(IMetricRecordService service) : base(service) { }
    }
}
