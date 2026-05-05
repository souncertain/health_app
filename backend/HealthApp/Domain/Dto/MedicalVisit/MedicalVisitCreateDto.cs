using Enums;

namespace Domain.Dto.MedicalVisit
{
    public class MedicalVisitCreateDto
    {
        public Guid UserId { get; set; }
        public string DoctorName { get; set; }
        public string Speciality { get; set; }
        public DateTime AppointmentDate { get; set; }
        public int TimeInMinutes { get; set; }
        public string Location { get; set; }
        public MedicalVisitType VisitType { get; set; }
    }
}
