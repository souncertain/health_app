using Domain.Dto.Profile;
using Domain.Entity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Services.Interfaces;

namespace HealthApp.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/profile")]
    public class ProfileController : AbstractController<Profile, ProfileCreateDto, ProfileDetailsDto, IProfileService>
    {
        private readonly IProfileService _profileService;

        public ProfileController(IProfileService service) : base(service)
        {
            _profileService = service;
        }

        [HttpGet("me")]
        public async Task<ProfilePageDto> GetCurrentProfilePage(CancellationToken ct)
        {
            return await _profileService.GetCurrentProfilePage(ct);
        }

        [HttpGet("me/stats")]
        public async Task<ProfileStatsDto> GetCurrentProfileStats(CancellationToken ct)
        {
            return await _profileService.GetCurrentProfileStats(ct);
        }

        [HttpGet("me/insights")]
        public async Task<ProfileHealthInsightsDto> GetCurrentHealthInsights(CancellationToken ct)
        {
            return await _profileService.GetCurrentHealthInsights(ct);
        }

        [HttpPut("me")]
        public async Task<ProfilePageDto> SaveCurrentProfile([FromBody] ProfilePageUpdateDto dto, CancellationToken ct)
        {
            return await _profileService.SaveCurrentProfile(dto, ct);
        }
    }
}
