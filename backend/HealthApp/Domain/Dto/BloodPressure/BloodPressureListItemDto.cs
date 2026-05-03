namespace HealthApp.Dtos.BloodPressure
{
    public class BloodPressureListItemDto
    {
        public Guid Id { get; set; }
        public int Systolic { get; set; }
        public int Diastolic { get; set; }
        public int Pulse { get; set; }
        public DateTime RecordedAt { get; set; }
        public string Category { get; set; } = string.Empty;
        public string PressureLabel { get; set; } = string.Empty;
    }
}
