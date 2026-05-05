using Domain.Dto.Profile;
using Domain.Dto.User;
using Domain.Entity;
using System.Text;

namespace Services.Mappers
{
    public class ProfileMapper : AutoMapper.Profile
    {
        public ProfileMapper()
        {
            CreateMap<ProfileCreateDto, Profile>()
                .ForMember(x => x.Id, y => y.MapFrom(source => Guid.NewGuid()))
                .ForMember(x => x.FirstName, y => y.MapFrom(source => source.FirstName))
                .ForMember(x => x.LastName, y => y.MapFrom(source => source.LastName))
                .ForMember(x => x.UserId, y => y.MapFrom(source => source.UserId))
                .ForMember(x => x.Birthday, y => y.MapFrom(source => source.Birthday))
                .ForMember(x => x.Sex, y => y.MapFrom(source => source.Sex))
                .ForMember(x => x.CreatedAt, y => y.MapFrom(source => DateTime.UtcNow))
                .ForMember(x => x.LastUpdatedAt, y => y.MapFrom(source => DateTime.UtcNow))
                .ForAllMembers(opts =>
                    opts.Condition((src, dest, srcMember) => srcMember != null)
                ); 

            CreateMap<Profile, ProfileDetailsDto>()
                .ForMember(x => x.Id, y => y.MapFrom(source => source.Id))
                .ForMember(x => x.FirstName, y => y.MapFrom(source => source.FirstName))
                .ForMember(x => x.LastName, y => y.MapFrom(source => source.LastName))
                .ForMember(x => x.UserId, y => y.MapFrom(source => source.UserId))
                .ForMember(x => x.Birthday, y => y.MapFrom(source => source.Birthday))
                .ForMember(x => x.Sex, y => y.MapFrom(source => source.Sex))
                .ForMember(x => x.AvatarUrl, y => y.MapFrom(source => source.AvatarUrl))
                .ForMember(x => x.Height, y => y.MapFrom(source => source.Height))
                .ForMember(x => x.Weight, y => y.MapFrom(source => source.Weight))
                .ForMember(x => x.BloodType, y => y.MapFrom(source => source.BloodType))
                .ForMember(x => x.ResusPhactor, y => y.MapFrom(source => source.ResusPhactor))
                .ForMember(x => x.CreatedAt, y => y.MapFrom(source => source.CreatedAt))
                .ForMember(x => x.LastUpdatedAt, y => y.MapFrom(source => source.LastUpdatedAt));
        }
    }
}
