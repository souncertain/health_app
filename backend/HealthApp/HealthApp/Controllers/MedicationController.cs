using Domain.Dto.Medication;
using Domain.Entity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Services.Interfaces;

namespace HealthApp.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/medications")]
    public class MedicationController : AbstractController<Medication, MedicationCreateDto, MedicationDetailsDto, IMedicationService>
    {
        private readonly IMedicationService _medicationService;

        public MedicationController(IMedicationService serviceBase) : base(serviceBase)
        {
            _medicationService = serviceBase;
        }

        [Route("soonest-notifications")]
        [HttpGet]
        public async Task<IEnumerable<MedicationSoonestNotificationDto>> GetSoonestNotifications()
        {
            return await _medicationService.GetSoonestNotification();
        }

        [Route("statuses")]
        [HttpGet]
        public async Task<MedicationStatusesDto> GetStatuses()
        {
            return await _medicationService.GetMedicationStatuses();
        }

        [HttpPut("{medicationId:guid}/daily-status")]
        public async Task<ActionResult<MedicationDailyStatusDetailsDto?>> SetDailyStatus(
            Guid medicationId,
            [FromBody] MedicationDailyStatusUpsertDto dto,
            CancellationToken ct)
        {
            var result = await _medicationService.SetMedicationDailyStatus(
                medicationId,
                dto.Date,
                dto.Status,
                ct);

            return result;
        }
    }
}
