using Domain.Dto.BloodPressure;
using Domain.Entity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Services.Interfaces;

namespace HealthApp.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/pressures")]
    public class BloodPressureController : AbstractController<BloodPressure, BloodPressureCreateDto, BloodPressureDetailsDto, IBloodPressureService>
    {
        private readonly IBloodPressureService _bloodPressureService;

        public BloodPressureController(IBloodPressureService service) : base(service)
        {
            _bloodPressureService = service;
        }

        [Route("interval")]
        [HttpGet]
        public async Task<IEnumerable<BloodPressureDetailsDto>> GetByDateInterval(int interval)
        {
            var result = await _bloodPressureService.GetByDateInterval(interval);
            return result;
        }

        [Route("average")]
        [HttpGet]
        public async Task<BloodPressureAverageDataDto> GetAverageData()
        {
            var result = await _bloodPressureService.GetAverageValues();
            return result;
        }

        [Route("last")]
        [HttpGet]
        public async Task<IEnumerable<BloodPressureDetailsDto>> GetLastRecords(int last)
        {
            var result = await _bloodPressureService.GetLastValues(last);
            return result;
        }
    }
}
