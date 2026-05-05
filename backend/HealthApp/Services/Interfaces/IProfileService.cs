using Domain.Dto.Profile;
using Domain.Entity;

namespace Services.Interfaces
{
    public interface IProfileService : IAbstractService<Profile, ProfileCreateDto, ProfileDetailsDto>
    {
    }
}
