using AutoMapper;
using Data.Interfaces;
using Domain.Dto.User;
using Domain.Entity;
using Services.Interfaces;
using Services.Validation.Infrastructure;

namespace Services.Services
{
    public class UserService : AbstractService<User, UserCreateDto, UserDetailsDto>, IUserService
    {
        public UserService(
            IUserRepository repository,
            IMapper mapper,
            IRequestValidationService validationService) : base(repository, mapper, validationService) { }
    }
}
