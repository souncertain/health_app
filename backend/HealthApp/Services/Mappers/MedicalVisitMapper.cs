using Domain.Dto.MedicalVisit;
using Domain.Dto.User;
using Domain.Entity;
using System.Diagnostics.Tracing;
using System.Text;

namespace Services.Mappers
{
    public class MedicalVisitMapper : AutoMapper.Profile
    {
        public MedicalVisitMapper() 
        {
            CreateMap<MedicalVisitCreateDto, MedicalVisit>()
                .ForMember(x => x.Id, y => y.MapFrom(source => Guid.NewGuid()))
                .ForMember(x => x.UserId, y => y.MapFrom(source => source.UserId))
                .ForMember(x => x.DoctorName, y => y.MapFrom(source => source.DoctorName))
                .ForMember(x => x.Specialty, y => y.MapFrom(source => source.Speciality))
                .ForMember(x => x.AppointmentDate, y => y.MapFrom(source => source.AppointmentDate))
                .ForMember(x => x.TimeInMinutes, y => y.MapFrom(source => source.TimeInMinutes))
                .ForMember(x => x.Location, y => y.MapFrom(source => source.Location))
                .ForMember(x => x.CreatedAt, y => y.MapFrom(source => DateTime.UtcNow))
                .ForMember(x => x.LastUpdatedAt, y => y.MapFrom(source => DateTime.UtcNow));

            CreateMap<MedicalVisit, MedicalVisitDetailsDto>()
                .ForMember(x => x.Id, y => y.MapFrom(source => source.Id))
                .ForMember(x => x.UserId, y => y.MapFrom(source => source.UserId))
                .ForMember(x => x.DoctorName, y => y.MapFrom(source => source.DoctorName))
                .ForMember(x => x.Speciality, y => y.MapFrom(source => source.Specialty))
                .ForMember(x => x.AppointmentDate, y => y.MapFrom(source => source.AppointmentDate))
                .ForMember(x => x.TimeInMinutes, y => y.MapFrom(source => source.TimeInMinutes))
                .ForMember(x => x.Location, y => y.MapFrom(source => source.Location))
                .ForMember(x => x.CreatedAt, y => y.MapFrom(source => source.CreatedAt))
                .ForMember(x => x.LastUpdatedAt, y => y.MapFrom(source => source.LastUpdatedAt));
        }
    }
}
