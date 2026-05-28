using AutoMapper;
using Data.Interfaces;
using Domain.Dto.MedicalVisit;
using Domain.Entity;
using Services.Interfaces;
using Services.Validation.Infrastructure;

namespace Services.Services
{
    public class MedicalVisitService : AbstractService<MedicalVisit, MedicalVisitCreateDto, MedicalVisitDetailsDto>, IMedicalVisitService
    {
        public MedicalVisitService(
            IMedicalVisitRepository repository,
            IMapper mapper,
            IRequestValidationService validationService) : base(repository, mapper, validationService) { }
    }
}
