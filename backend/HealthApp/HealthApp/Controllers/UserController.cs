using Domain.Dto.User;
using Domain.Entity;
using Microsoft.AspNetCore.Mvc;
using Services.Interfaces;

namespace HealthApp.Controllers
{
    [ApiController]
    [Route("api/user")]
    public class UserController : AbstractController<User, UserCreateDto, UserDetailedDto, IUserService>
    {
        public UserController(IUserService service) : base(service) { }
    }
}
