using Domain.Dto.Medication;
using Domain.Entity;

namespace Services.Interfaces
{
    public interface IMedicationService : IAbstractService<Medication, MedicationCreateDto, MedicationDetailsDto>
    {
    }
}
