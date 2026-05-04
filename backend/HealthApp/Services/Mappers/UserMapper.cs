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
                .ForMember(x => x.Id, y => y.MapFrom(source => Guid.NewGuid()))
                .ForMember(x => x.Email, y => y.MapFrom(source => source.Email))
                .ForMember(x => x.Password, y => y.MapFrom(source => Encoding.UTF8.GetBytes(source.Password)))
                .ForMember(x => x.Phone, y => y.MapFrom(source => source.Phone))
                .ForMember(x => x.CreatedAt, y => y.MapFrom(source => DateTime.UtcNow))
                .ForMember(x => x.LastUpdatedAt, y => y.MapFrom(source => DateTime.UtcNow));

            CreateMap<User, UserDetailedDto>()
                .ForMember(x => x.Id, y => y.MapFrom(source => source.Id))
                .ForMember(x => x.Email, y => y.MapFrom(source => source.Email))
                .ForMember(x => x.Phone, y => y.MapFrom(source => source.Phone))
                .ForMember(x => x.CreatedAt, y => y.MapFrom(source => source.CreatedAt))
                .ForMember(x => x.LastUpdatedAt, y => y.MapFrom(source => source.LastUpdatedAt));
        }
    }
}
