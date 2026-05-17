using Domain.Dto.Profile;
using Domain.Entity;

namespace Services.Interfaces
{
    public interface IProfileService : IAbstractService<Profile, ProfileCreateDto, ProfileDetailsDto>
    {
        Task<ProfilePageDto> GetCurrentProfilePage(CancellationToken ct);
        Task<ProfileStatsDto> GetCurrentProfileStats(CancellationToken ct);
        Task<ProfilePageDto> SaveCurrentProfile(ProfilePageUpdateDto dto, CancellationToken ct);
    }
}
