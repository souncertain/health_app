using AutoMapper;
using Domain.Dto.BloodPressure;
using Domain.Entity;

namespace Services.Mappers
{
    public class BloodPressureMapper : AutoMapper.Profile
    {
        public BloodPressureMapper() 
        {
            CreateMap<BloodPressure, BloodPressureDetailsDto>()
                .ForMember(x => x.Id, y => y.MapFrom(y => y.Id))
                .ForMember(x => x.UserId, y => y.MapFrom(y => y.UserId))
                .ForMember(x => x.Systolic, y => y.MapFrom(y => y.Systolic))
                .ForMember(x => x.Diastolic, y => y.MapFrom(y => y.Diastolic))
                .ForMember(x => x.Pulse, y => y.MapFrom(y => y.Pulse))
                .ForMember(x => x.CreatedAt, y => y.MapFrom(y => y.CreatedAt))
                .ForMember(x => x.LastUpdatedAt, y => y.MapFrom(y => y.LastUpdatedAt))
                .ForMember(x => x.Source, y => y.MapFrom(y => y.Source.ToString()))
                .ForMember(x => x.Category, y => y.MapFrom(y => y.Category.ToString()))
                .ForMember(x => x.PressureLabel, y => y.MapFrom(y => $"{y.Systolic}/{y.Diastolic}"));

            CreateMap<BloodPressureCreateDto, BloodPressure>()
                .ForMember(x => x.Id, y => y.MapFrom(source => Guid.NewGuid()))
                .ForMember(x => x.UserId, y => y.MapFrom(source => source.UserId))
                .ForMember(x => x.Systolic, y => y.MapFrom(source => source.Systolic))
                .ForMember(x => x.Diastolic, y => y.MapFrom(source => source.Diastolic))
                .ForMember(x => x.Pulse, y => y.MapFrom(source => source.Pulse))
                .ForMember(x => x.RecordedAt, y => y.MapFrom(source => source.RecordedAt))
                .ForMember(x => x.Source, y => y.MapFrom(source => source.Source))
                .ForMember(x => x.CreatedAt, y => y.MapFrom(source => DateTime.UtcNow))
                .ForMember(x => x.LastUpdatedAt, y => y.MapFrom(source => DateTime.UtcNow));
        }
    }
}
