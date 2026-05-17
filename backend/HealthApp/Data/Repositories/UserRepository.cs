using Data.Interfaces;
using Domain.Entity;

namespace Data.Repositories
{
    public class UserRepository : AbstractRepository<User>, IUserRepository
    {
        public UserRepository(HealthAppDbContext context, ICurrentUserContext currentUserContext)
            : base(context, currentUserContext) { }
    }
}
