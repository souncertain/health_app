using Data.Interfaces;
using Domain.Entity;

namespace Data.Repositories
{
    public class MedicationRepository : AbstractRepository<Medication>, IMedicationRepository
    {
        public MedicationRepository(HealthAppDbContext context) : base(context)
        {
        }
    }
}
