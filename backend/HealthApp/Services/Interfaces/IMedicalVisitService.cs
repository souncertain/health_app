using Domain.Dto.MedicalVisit;
using Domain.Entity;

namespace Services.Interfaces
{
    public interface IMedicalVisitService : IAbstractService<MedicalVisit, MedicalVisitCreateDto, MedicalVisitDetailsDto>
    {
    }
}
