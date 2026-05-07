using Domain.Dto.BloodPressure;
using Domain.Entity;

namespace Services.Interfaces
{
    public interface IBloodPressureService : IAbstractService<BloodPressure, BloodPressureCreateDto, BloodPressureDetailsDto>
    {
        Task<IEnumerable<BloodPressureDetailsDto>> GetByDateInterval(int interval);
        Task<BloodPressureAverageDataDto> GetAverageValues();
        Task<IEnumerable<BloodPressureDetailsDto>> GetLastValues(int last);
    }
}
