using Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Domain.Entity
{
    [Table("medications")]
    public class Medication
    {
        [Key]
        public Guid Id { get; set; }
        public Guid UserId { get; set; }

        [Required]
        [MaxLength(30)]
        public string Name { get; set; } = string.Empty;
        [Range(0.001, 100000)]
        public double DosageValue { get; set; }
        [Required]
        [MaxLength(30)]
        public string DosageUnit { get; set; } = string.Empty;
        public MedicationFrequency Frequency { get; set; }
        public List<int> TimesInMinutes { get; set; } = new List<int>();
        public bool NotificationsEnabled { get; set; }
        public List<int> ScheduledWeekdays { get; set; } = new List<int>();
        public Dictionary<int, MedicationDayStatus> DayStatuses { get; set; } = new Dictionary<int, MedicationDayStatus>();
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }

        [ForeignKey(nameof(UserId))]
        [InverseProperty(nameof(Entity.User.Medications))]
        public User? User { get; set; }

        public bool IsScheduledForWeekday(int weekday)
        {
            return ScheduledWeekdays.Contains(weekday);
        }

        public MedicationDayStatus? StatusForWeekday(int weekday)
        {
            if (!IsScheduledForWeekday(weekday))
            {
                return null;
            }

            return DayStatuses.TryGetValue(weekday, out var status)
                ? status
                : MedicationDayStatus.Pending;
        }
    }
}
