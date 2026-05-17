using Data.Interfaces;
using Domain.Entity;

namespace Data.Repositories
{
    public class MedicalVisitRepository : AbstractRepository<MedicalVisit>, IMedicalVisitRepository
    {
        public MedicalVisitRepository(HealthAppDbContext context, ICurrentUserContext currentUserContext)
            : base(context, currentUserContext) { }
    }
}
