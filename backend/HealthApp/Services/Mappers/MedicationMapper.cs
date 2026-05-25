using Domain.Dto.Medication;
using Domain.Entity;

namespace Services.Mappers
{
    public class MedicationMapper : AutoMapper.Profile
    {
        public MedicationMapper()
        {
            CreateMap<MedicationCreateDto, Medication>()
                .ForMember(x => x.Id, y => y.MapFrom(source => Guid.NewGuid()))
                .ForMember(x => x.UserId, y => y.MapFrom(source => source.UserId))
                .ForMember(x => x.Name, y => y.MapFrom(source => source.Name))
                .ForMember(x => x.DosageValue, y => y.MapFrom(source => source.DosageValue))
                .ForMember(x => x.DosageUnit, y => y.MapFrom(source => source.DosageUnit))
                .ForMember(x => x.Frequency, y => y.MapFrom(source => source.Frequency))
                .ForMember(x => x.TimesInMinutes, y => y.MapFrom(source => source.TimesInMinutes))
                .ForMember(x => x.NotificationsEnabled, y => y.MapFrom(source => source.NotificationsEnabled))
                .ForMember(x => x.ScheduledWeekdays, y => y.MapFrom(source => source.ScheduledWeekdays))
                .ForMember(x => x.CreatedAt, y => y.Ignore())
                .ForMember(x => x.LastUpdatedAt, y => y.Ignore());

            CreateMap<Medication, MedicationDetailsDto>()
                .ForMember(x => x.Id, y => y.MapFrom(source => source.Id))
                .ForMember(x => x.UserId, y => y.MapFrom(source => source.UserId))
                .ForMember(x => x.Name, y => y.MapFrom(source => source.Name))
                .ForMember(x => x.DosageValue, y => y.MapFrom(source => source.DosageValue))
                .ForMember(x => x.DosageUnit, y => y.MapFrom(source => source.DosageUnit))
                .ForMember(x => x.Frequency, y => y.MapFrom(source => source.Frequency))
                .ForMember(x => x.TimesInMinutes, y => y.MapFrom(source => source.TimesInMinutes))
                .ForMember(x => x.NotificationsEnabled, y => y.MapFrom(source => source.NotificationsEnabled))
                .ForMember(x => x.ScheduledWeekdays, y => y.MapFrom(source => source.ScheduledWeekdays))
                .ForMember(x => x.DailyStatuses, y => y.MapFrom(source => source.DailyStatuses))
                .ForMember(x => x.CreatedAt, y => y.MapFrom(source => source.CreatedAt))
                .ForMember(x => x.LastUpdatedAt, y => y.MapFrom(source => source.LastUpdatedAt));

            CreateMap<MedicationDailyStatus, MedicationDailyStatusDetailsDto>()
                .ForMember(x => x.Id, y => y.MapFrom(source => source.Id))
                .ForMember(x => x.MedicationId, y => y.MapFrom(source => source.MedicationId))
                .ForMember(x => x.Date, y => y.MapFrom(source => source.Date))
                .ForMember(x => x.Status, y => y.MapFrom(source => source.Status))
                .ForMember(x => x.CreatedAt, y => y.MapFrom(source => source.CreatedAt))
                .ForMember(x => x.LastUpdatedAt, y => y.MapFrom(source => source.LastUpdatedAt));
        }
    }
}
