namespace Domain.Dto.Medication
{
    public class MedicationSoonestNotificationDto
    {
        public string Name { get; set; } = string.Empty;
        public double DosageValue { get; set; }
        public string DosageUnit { get; set; } = string.Empty;
        public DateTime ScheduledAt { get; set; }
        public TimeOnly SoonestNotificationTime { get; set; }
    }
}
