using Data.Interfaces;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Domain.Entity
{
    [Table("users")]
    public class User : IHasId
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
        public byte[] Password { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }

        [InverseProperty(nameof(Entity.Profile.User))]
        public Profile? Profile { get; set; }

        [InverseProperty(nameof(BloodPressure.User))]
        public ICollection<BloodPressure> BloodPressures { get; set; } = new List<BloodPressure>();

        [InverseProperty(nameof(Medication.User))]
        public ICollection<Medication> Medications { get; set; } = new List<Medication>();

        [InverseProperty(nameof(HealthMetric.User))]
        public ICollection<HealthMetric> HealthMetrics { get; set; } = new List<HealthMetric>();

        [InverseProperty(nameof(MedicalVisit.User))]
        public ICollection<MedicalVisit> MedicalVisits { get; set; } = new List<MedicalVisit>();
    }
}
