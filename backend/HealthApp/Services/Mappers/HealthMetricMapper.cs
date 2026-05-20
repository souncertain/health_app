using Domain.Dto.HealthMetric;
using Domain.Dto.MetricRecords;
using Domain.Entity;

namespace Services.Mappers
{
    public class HealthMetricMapper : AutoMapper.Profile
    {
        public HealthMetricMapper()
        {
            CreateMap<HealthMetricCreateDto, HealthMetric>()
                .ForMember(x => x.Id, y => y.MapFrom(source => Guid.NewGuid()))
                .ForMember(x => x.TargetMin, y => y.MapFrom(source => source.TargetMin))
                .ForMember(x => x.TargetMax, y => y.MapFrom(source => source.TargetMax))
                .ForMember(x => x.IsCustom, y => y.MapFrom(source => true))
                .ForMember(x => x.Title, y => y.MapFrom(source => source.Title))
                .ForMember(x => x.UserId, y => y.MapFrom(source => source.UserId))
                .ForMember(x => x.VisualStyle, y => y.MapFrom(source => source.VisualStyle))
                .ForMember(x => x.Unit, y => y.MapFrom(source => source.Unit))
                .ForMember(x => x.CreatedAt, y => y.Ignore())
                .ForMember(x => x.LastUpdatedAt, y => y.Ignore());

            CreateMap<HealthMetric, HealthMetricDetailsDto>()
                .ForMember(x => x.Id, y => y.MapFrom(source => source.Id))
                .ForMember(x => x.TargetMin, y => y.MapFrom(source => source.TargetMin))
                .ForMember(x => x.TargetMax, y => y.MapFrom(source => source.TargetMax))
                .ForMember(x => x.IsCustom, y => y.MapFrom(source => true))
                .ForMember(x => x.Title, y => y.MapFrom(source => source.Title))
                .ForMember(x => x.UserId, y => y.MapFrom(source => source.UserId))
                .ForMember(x => x.VisualStyle, y => y.MapFrom(source => source.VisualStyle))
                .ForMember(x => x.Unit, y => y.MapFrom(source => source.Unit))
                .ForMember(x => x.CreatedAt, y => y.MapFrom(source => source.CreatedAt))
                .ForMember(x => x.LastUpdatedAt, y => y.MapFrom(source => source.LastUpdatedAt));
        }
    }
}
