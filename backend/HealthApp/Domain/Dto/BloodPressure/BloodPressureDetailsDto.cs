namespace HealthApp.Dtos.BloodPressure
{
    public class BloodPressureDetailsDto
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public int Systolic { get; set; }
        public int Diastolic { get; set; }
        public int Pulse { get; set; }
        public DateTime RecordedAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }
        public string Source { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public string PressureLabel { get; set; } = string.Empty;
    }
}
