using Data.Interfaces;
using Domain.Entity;

namespace Data.Repositories
{
    public class BloodPressureRepository : AbstractRepository<BloodPressure> , IBloodPressureRepository 
    {
        public BloodPressureRepository(HealthAppDbContext context) : base(context)
        {
        }
    }
}
