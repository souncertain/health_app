using Domain.Dto.Profile;
using Domain.Entity;
using Microsoft.AspNetCore.Mvc;
using Services.Interfaces;

namespace HealthApp.Controllers
{
    [ApiController]
    [Route("api/profile")]
    public class ProfileController : AbstractController<Profile, ProfileCreateDto, ProfileDetailsDto, IProfileService>
    {
        public ProfileController(IProfileService service) : base (service){ }
    }
}
