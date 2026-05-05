using Enums;

namespace Domain.Dto.Medication
{
    public class MedicationDetailsDto
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string Name { get; set; }
        public double DosageValue { get; set; }
        public string DosageUnit { get; set; }
        public MedicationFrequency Frequency { get; set; }
        public List<int> TimesInMinutes { get; set; }
        public bool NotificationsEnabled { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }
    }
}
