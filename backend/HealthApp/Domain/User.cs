using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Domain
{
    [Table("users")]
    public class User
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        [MaxLength(20)]
        public string Phone { get; set; } = string.Empty;

        [Required]
        [MaxLength(255)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MaxLength(255)]
        public string Password { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }

        [InverseProperty(nameof(Domain.Profile.User))]
        public Profile? Profile { get; set; }

        [InverseProperty(nameof(Domain.BloodPressure.User))]
        public ICollection<BloodPressure> BloodPressures { get; set; } = new List<BloodPressure>();

        [InverseProperty(nameof(Domain.Medication.User))]
        public ICollection<Medication> Medications { get; set; } = new List<Medication>();

        [InverseProperty(nameof(Domain.HealthMetric.User))]
        public ICollection<HealthMetric> HealthMetrics { get; set; } = new List<HealthMetric>();

        [InverseProperty(nameof(Domain.MedicalVisit.User))]
        public ICollection<MedicalVisit> MedicalVisits { get; set; } = new List<MedicalVisit>();
    }
}
