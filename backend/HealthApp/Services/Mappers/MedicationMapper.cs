using Domain.Dto.MedicalVisit;
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
                .ForMember(x => x.CreatedAt, y => y.MapFrom(source => DateTime.UtcNow))
                .ForMember(x => x.LastUpdatedAt, y => y.MapFrom(source => DateTime.UtcNow));

            CreateMap<Medication, MedicationDetailsDto>()
                .ForMember(x => x.Id, y => y.MapFrom(source => source.Id))
                .ForMember(x => x.UserId, y => y.MapFrom(source => source.UserId))
                .ForMember(x => x.Name, y => y.MapFrom(source => source.Name))
                .ForMember(x => x.DosageValue, y => y.MapFrom(source => source.DosageValue))
                .ForMember(x => x.DosageUnit, y => y.MapFrom(source => source.DosageUnit))
                .ForMember(x => x.Frequency, y => y.MapFrom(source => source.Frequency))
                .ForMember(x => x.TimesInMinutes, y => y.MapFrom(source => source.TimesInMinutes))
                //.ForMember(x => x.MedicationStatus, y => y.MapFrom(source => source.DayStatuses[DateTime.UtcNow]))
                .ForMember(x => x.NotificationsEnabled, y => y.MapFrom(source => source.NotificationsEnabled))
                .ForMember(x => x.CreatedAt, y => y.MapFrom(source => source.CreatedAt))
                .ForMember(x => x.LastUpdatedAt, y => y.MapFrom(source => source.LastUpdatedAt));
        }
    }
}
