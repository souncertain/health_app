using Services.Interfaces;
using Data.Interfaces;
using Domain.Dto.BloodPressure;
using AutoMapper;
using Domain.Entity;

namespace Services.Services
{
    public class BloodPressureService : AbstractService<BloodPressure, BloodPressureCreateDto, BloodPressureDetailsDto>, IBloodPressureService
    {
        public BloodPressureService(IBloodPressureRepository repository, IMapper mapper) : base(repository, mapper) 
        {
        }
    }
}
