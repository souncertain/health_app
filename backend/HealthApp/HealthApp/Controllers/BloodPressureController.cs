using HealthApp.Dtos.BloodPressure;
using Microsoft.AspNetCore.Mvc;
using Services.Interfaces;

namespace HealthApp.Controllers
{
    [ApiController]
    [Route("api/pressure")]
    public class BloodPressureController : Controller
    {
        private readonly IBloodPressureService _service;

        public BloodPressureController(IBloodPressureService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<ActionResult<List<BloodPressureListItemDto>>> GetAll(CancellationToken ct)
        {
            var bloodPressures = await _service.GetAll(ct);
            var response = bloodPressures
                .Select(x => x.ToListItemDto())
                .ToList();

            return Ok(response);
        }
    }
}
