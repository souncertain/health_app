using AutoMapper;
using Data.Interfaces;
using Domain.Dto.Profile;
using Services.Interfaces;

namespace Services.Services
{
    public class ProfileService : AbstractService<Domain.Entity.Profile, ProfileCreateDto, ProfileDetailsDto>, IProfileService
    {
        public ProfileService(IProfileRepository repository, IMapper mapper) : base(repository, mapper) { }
    }
}
