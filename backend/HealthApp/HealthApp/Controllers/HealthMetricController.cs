using Domain.Dto.HealthMetric;
using Domain.Entity;
using Microsoft.AspNetCore.Mvc;
using Services.Interfaces;

namespace HealthApp.Controllers
{
    [ApiController]
    [Route("api/healthmetric")]
    public class HealthMetricController : AbstractController<HealthMetric, HealthMetricCreateDto, HealthMetricDetailsDto, IHealthMetricService>
    {
        public HealthMetricController(IHealthMetricService service) : base(service){ }
    }
}
