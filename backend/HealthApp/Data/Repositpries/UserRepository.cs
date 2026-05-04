using Data.Interfaces;
using Domain.Entity;

namespace Data.Repositpries
{
    public class UserRepository : AbstractRepository<User>, IUserRepository
    {
        public UserRepository(HealthAppDbContext context) : base(context) { }
    }
}
