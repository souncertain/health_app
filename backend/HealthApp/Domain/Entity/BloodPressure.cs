using Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Domain.Entity
{
    [Table("blood_pressures")]
    public class BloodPressure
    {
        [Key]
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        [Range(40, 300)]
        public int Systolic { get; set; }
        [Range(30, 200)]
        public int Diastolic { get; set; }
        [Range(20, 250)]
        public int Pulse { get; set; }
        public DateTime RecordedAt { get; set; }
        public BloodPressureSource Source { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }

        [ForeignKey(nameof(UserId))]
        [InverseProperty(nameof(Entity.User.BloodPressures))]
        public User? User { get; set; }

        [NotMapped]
        public BloodPressureCategory Category
        {
            get
            {
                if (Systolic >= 180 || Diastolic >= 120)
                {
                    return BloodPressureCategory.HypertensiveCrisis;
                }

                if (Systolic >= 140 || Diastolic >= 90)
                {
                    return BloodPressureCategory.HighStage2;
                }

                if (Systolic >= 130 || Diastolic >= 80)
                {
                    return BloodPressureCategory.HighStage1;
                }

                if (Systolic >= 120 && Diastolic < 80)
                {
                    return BloodPressureCategory.Elevated;
                }

                return BloodPressureCategory.Normal;
            }
        }
    }
}
