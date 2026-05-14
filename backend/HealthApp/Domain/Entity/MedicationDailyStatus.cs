using Data.Interfaces;
using Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Domain.Entity
{
    [Table("medication_daily_statuses")]
    public class MedicationDailyStatus : IHasId
    {
        [Key]
        public Guid Id { get; set; }
        public Guid MedicationId { get; set; }
        public DateOnly Date { get; set; }
        public MedicationDayStatus Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }

        [ForeignKey(nameof(MedicationId))]
        [InverseProperty(nameof(Entity.Medication.DailyStatuses))]
        public Medication? Medication { get; set; }
    }
}
