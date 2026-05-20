using Domain.Dto.HealthMetric;
using Domain.Entity;
using Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Services.Interfaces;

namespace HealthApp.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/healthmetric")]
    public class HealthMetricController : AbstractController<HealthMetric, HealthMetricCreateDto, HealthMetricDetailsDto, IHealthMetricService>
    {
        private readonly IHealthMetricService _healthMetricService;

        public HealthMetricController(IHealthMetricService service) : base(service)
        {
            _healthMetricService = service;
        }

        [Route("record")]
        [HttpPatch]
        public async Task<HealthMetricDetailsDto> AddRecordToHealthMetric(Guid metricRecordId, Guid metricId)
        {
            return await _healthMetricService.AddRecordToHealthMetric(metricRecordId, metricId);
        }

        [Route("type")]
        [HttpGet]
        public async Task<MetricTrend> GetMetricTrend(Guid metricId)
        {
            return await _healthMetricService.GetMetricTrend(metricId);
        }
    }
}
