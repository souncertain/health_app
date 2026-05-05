using Domain.Dto.User;
using Domain.Entity;
using Microsoft.AspNetCore.Mvc;
using Services.Interfaces;

namespace HealthApp.Controllers
{
    [ApiController]
    [Route("api/users")]
    public class UserController : AbstractController<User, UserCreateDto, UserDetailsDto, IUserService>
    {
        public UserController(IUserService service) : base(service) { }
    }
}
