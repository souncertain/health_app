using Domain.Dto.MetricRecords;
using Domain.Entity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Services.Interfaces;

namespace HealthApp.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/metricrecord")]
    public class MetricRecordController : AbstractController<MetricRecord, MetricRecordCreateDto, MetricRecordDetailsDto, IMetricRecordService>
    {
        private readonly IMetricRecordService _metricRecordService;

        public MetricRecordController(IMetricRecordService service) : base(service)
        {
            _metricRecordService = service;
        }

        [Route("graph")]
        [HttpGet]
        public async Task<IEnumerable<MetricRecordGraphProjection>> GetMetricRecordGraphProjections()
        {
            return await _metricRecordService.GetMetricRecordGraphProjections();
        }
    }
}
