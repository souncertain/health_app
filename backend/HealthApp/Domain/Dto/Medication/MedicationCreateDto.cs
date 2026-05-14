using Enums;

namespace Domain.Dto.Medication
{
    public class MedicationCreateDto
    {
        public Guid UserId { get; set; }
        public string Name { get; set; } = string.Empty;
        public double DosageValue { get; set; }
        public string DosageUnit { get; set; } = string.Empty;
        public MedicationFrequency Frequency { get; set; }
        public List<int> TimesInMinutes { get; set; } = new List<int>();
        public bool NotificationsEnabled { get; set; }
        public List<int> ScheduledWeekdays { get; set; } = new List<int>();
    }
}
