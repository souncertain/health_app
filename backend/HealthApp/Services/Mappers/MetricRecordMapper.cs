using Domain.Dto.MetricRecords;
using Domain.Entity;

namespace Services.Mappers
{
    public class MetricRecordMapper : AutoMapper.Profile
    {
        public MetricRecordMapper() 
        {
            CreateMap<MetricRecordCreateDto, MetricRecord>()
                .ForMember(x => x.Id, y => y.MapFrom(source => Guid.NewGuid()))
                .ForMember(x => x.HealthMetricId, y => y.MapFrom(source => source.HealthMetricId))
                .ForMember(x => x.Value, y => y.MapFrom(source => source.Value))
                .ForMember(x => x.CreatedAt, y => y.Ignore())
                .ForMember(x => x.LastUpdatedAt, y => y.Ignore());

            CreateMap<MetricRecord, MetricRecordDetailsDto>()
                .ForMember(x => x.Id, y => y.MapFrom(source => source.Id))
                .ForMember(x => x.HealthMetricId, y => y.MapFrom(source => source.HealthMetricId))
                .ForMember(x => x.Value, y => y.MapFrom(source => source.Value))
                .ForMember(x => x.CreatedAt, y => y.MapFrom(source => source.CreatedAt))
                .ForMember(x => x.LastUpdatedAt, y => y.MapFrom(source => source.LastUpdatedAt));
        }
    }
}
