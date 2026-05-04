using Data.Interfaces;
using Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Domain.Entity
{
    [Table("medical_visits")]
    public class MedicalVisit : IHasId
    {
        [Key]
        public Guid Id { get; set; }
        public Guid UserId { get; set; }

        [Required]
        [MaxLength(120)]
        public string DoctorName { get; set; } = string.Empty;

        [Required]
        [MaxLength(120)]
        public string Specialty { get; set; } = string.Empty;

        public DateTime AppointmentDate { get; set; }

        [Range(0, 1439)]
        public int TimeInMinutes { get; set; }

        [Required]
        [MaxLength(255)]
        public string Location { get; set; } = string.Empty;
        public MedicalVisitType VisitType { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }

        [ForeignKey(nameof(UserId))]
        [InverseProperty(nameof(Entity.User.MedicalVisits))]
        public User? User { get; set; }

        [NotMapped]
        public DateTime ScheduledAt
        {
            get
            {
                return new DateTime(
                    AppointmentDate.Year,
                    AppointmentDate.Month,
                    AppointmentDate.Day,
                    TimeInMinutes / 60,
                    TimeInMinutes % 60,
                    0);
            }
        }
    }
}
