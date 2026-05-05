using Domain.Dto.Medication;
using Domain.Entity;
using Microsoft.AspNetCore.Mvc;
using Services.Interfaces;

namespace HealthApp.Controllers
{
    [ApiController]
    [Route("api/medications")]
    public class MedicationController : AbstractController<Medication, MedicationCreateDto, MedicationDetailsDto, IMedicationService>
    {
        public MedicationController(IMedicationService serviceBase) : base(serviceBase)
        {
        }
    }
}
