using AutoMapper;
using Data.Interfaces;
using Domain.Dto.Medication;
using Domain.Entity;
using Services.Interfaces;

namespace Services.Services
{
    public class MedicationService : AbstractService<Medication, MedicationCreateDto, MedicationDetailsDto>, IMedicationService
    {
        public MedicationService(IMedicationRepository repository, IMapper mapper) : base(repository, mapper) { }
    }
}
