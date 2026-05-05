using Enums;

namespace Domain.Dto.MedicalVisit
{
    public class MedicalVisitDetailsDto
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string DoctorName { get; set; }
        public string Speciality { get; set; }
        public DateTime AppointmentDate { get; set; }
        public int TimeInMinutes { get; set; }
        public string Location { get; set; }
        public MedicalVisitType VisitType { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt{ get; set; }
        public DateTime ScheduledAt { get; set; }
    }
}
