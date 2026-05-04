using Domain.Dto.User;
using Domain.Entity;

namespace Services.Interfaces
{
    public interface IUserService : IAbstractService<User, UserCreateDto, UserDetailedDto>
    {
    }
}
