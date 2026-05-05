using Domain.Dto.BloodPressure;
using Domain.Entity;
using Microsoft.AspNetCore.Mvc;
using Services.Interfaces;

namespace HealthApp.Controllers
{
    [ApiController]
    [Route("api/pressures")]
    public class BloodPressureController : AbstractController<BloodPressure, BloodPressureCreateDto, BloodPressureDetailsDto, IBloodPressureService>
    {
        public BloodPressureController(IBloodPressureService service) : base(service)
        {
        }
    }
}
