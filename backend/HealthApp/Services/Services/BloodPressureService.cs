using Services.Interfaces;
using Data.Interfaces;
using Domain.Dto.BloodPressure;
using AutoMapper;
using Domain.Entity;

namespace Services.Services
{
    public class BloodPressureService : AbstractService<BloodPressure, BloodPressureCreateDto, BloodPressureDetailsDto>, IBloodPressureService
    {
        private readonly IBloodPressureRepository _bloodPressureRepository;
        public BloodPressureService(IBloodPressureRepository repository, IMapper mapper) : base(repository, mapper) 
        {
            _bloodPressureRepository = repository;
        }

        public async Task<IEnumerable<BloodPressureDetailsDto>> GetByDateInterval(int interval)
        {
            var bloodPressures = await _bloodPressureRepository.GetByDateInterval(interval);
            return _mapper.Map<List<BloodPressureDetailsDto>>(bloodPressures);
        }

        public async Task <BloodPressureAverageDataDto> GetAverageValues()
        {
            var (systolic, diastolic, pulse) = await _bloodPressureRepository.GetAverageValues();
            var dto = new BloodPressureAverageDataDto()
            {
                Systolic = systolic,
                Diastolic = diastolic,
                Pulse = pulse,
            };
            return dto;
        }

        public async Task<IEnumerable<BloodPressureDetailsDto>> GetLastValues(int last)
        {
            var lastValues = await _bloodPressureRepository.GetLastValues(last);
            return _mapper.Map<List<BloodPressureDetailsDto>>(lastValues);
        }
    }
}
