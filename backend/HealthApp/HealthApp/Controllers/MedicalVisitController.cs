using Domain.Dto.MedicalVisit;
using Domain.Entity;
using Microsoft.AspNetCore.Mvc;
using Services.Interfaces;

namespace HealthApp.Controllers
{
    [ApiController]
    [Route("api/visits")]
    public class MedicalVisitController : AbstractController<MedicalVisit, MedicalVisitCreateDto, MedicalVisitDetailsDto, IMedicalVisitService>
    {
        public MedicalVisitController(IMedicalVisitService service) : base(service)
        {
        }
    }
}
