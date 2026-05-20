using Domain.Dto.User;
using Domain.Entity;
using System.Text;

namespace Services.Mappers
{
    public class UserMapper : AutoMapper.Profile
    {
        public UserMapper()
        {
            CreateMap<UserCreateDto, User>()
                .ForMember(x => x.Id, y => y.MapFrom(_ => Guid.NewGuid()))
                .ForMember(x => x.Email, y => y.MapFrom(source => source.Email.Trim().ToLowerInvariant()))
                .ForMember(x => x.PasswordHash, y => y.MapFrom(source =>
                    string.IsNullOrWhiteSpace(source.Password)
                        ? null
                        : $"legacy:{Convert.ToBase64String(Encoding.UTF8.GetBytes(source.Password))}"))
                .ForMember(x => x.Phone, y => y.MapFrom(source =>
                    string.IsNullOrWhiteSpace(source.Phone) ? null : source.Phone.Trim()))
                .ForMember(x => x.CreatedAt, y => y.Ignore())
                .ForMember(x => x.LastUpdatedAt, y => y.Ignore());

            CreateMap<User, UserDetailsDto>()
                .ForMember(x => x.Id, y => y.MapFrom(source => source.Id))
                .ForMember(x => x.Email, y => y.MapFrom(source => source.Email))
                .ForMember(x => x.Phone, y => y.MapFrom(source => source.Phone))
                .ForMember(x => x.CreatedAt, y => y.MapFrom(source => source.CreatedAt))
                .ForMember(x => x.LastUpdatedAt, y => y.MapFrom(source => source.LastUpdatedAt));
        }
    }
}
