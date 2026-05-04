using Domain.Dto.BloodPressure;
using Domain.Entity;

namespace Services.Interfaces
{
    public interface IBloodPressureService : IAbstractService<BloodPressure, BloodPressureCreateDto, BloodPressureDetailsDto>
    {
    }
}
