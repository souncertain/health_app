namespace Domain.Dto.Medication
{
    public class MedicationSoonestNotificationDto
    {
        public string Name { get; set; }
        public double DosageValue { get; set; }
        public string DosageUnit { get; set; }
        public TimeOnly SoonestNotificationTime { get; set; }
    }
}
