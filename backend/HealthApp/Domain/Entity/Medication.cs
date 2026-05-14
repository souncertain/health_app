using Data.Interfaces;
using Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Domain.Entity
{
    [Table("medications")]
    public class Medication : IHasId
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
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }

        [ForeignKey(nameof(UserId))]
        [InverseProperty(nameof(Entity.User.Medications))]
        public User? User { get; set; }

        [InverseProperty(nameof(MedicationDailyStatus.Medication))]
        public ICollection<MedicationDailyStatus> DailyStatuses { get; set; } = new List<MedicationDailyStatus>();

        public bool IsScheduledForWeekday(int isoWeekday)
        {
            return ScheduledWeekdays.Contains(isoWeekday);
        }

        public bool IsScheduledForDate(DateOnly date)
        {
            return IsScheduledForWeekday(ToIsoWeekday(date.DayOfWeek));
        }

        public static int ToIsoWeekday(DayOfWeek dayOfWeek)
        {
            return dayOfWeek == DayOfWeek.Sunday ? 7 : (int)dayOfWeek;
        }
    }
}
