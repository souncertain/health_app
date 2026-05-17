using Domain.Dto.Profile;
using Domain.Entity;

namespace Data.Interfaces
{
    public interface IProfileRepository : IAbstractRepository<Profile>
    {
        Task<Profile?> GetCurrentProfile(CancellationToken ct = default);
        Task<User?> GetCurrentUser(CancellationToken ct = default);
        Task<ProfileStatsDto> GetCurrentProfileStats(CancellationToken ct = default);
    }
}
