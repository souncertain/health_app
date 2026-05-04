using AutoMapper;
using Data.Interfaces;
using Domain.Dto.User;
using Domain.Entity;
using Services.Interfaces;

namespace Services.Services
{
    public class UserService : AbstractService<User, UserCreateDto, UserDetailedDto>, IUserService
    {
        public UserService(IUserRepository repository, IMapper mapper) : base (repository, mapper){ }
    }
}
