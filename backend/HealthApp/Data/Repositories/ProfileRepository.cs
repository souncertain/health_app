using Data.Interfaces;
using Domain.Entity;

namespace Data.Repositories
{
    public class ProfileRepository : AbstractRepository<Profile>, IProfileRepository
    {
        public ProfileRepository(HealthAppDbContext context) : base(context)
        {
        }
    }
}
