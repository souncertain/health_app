namespace Domain.Dto.BloodPressure
{
    public class BloodPressureCreateDto
    {
        public Guid UserId { get; set; }
        public int Systolic { get; set; }
        public int Diastolic { get; set; }
        public int Pulse { get; set; }
        public DateTime RecordedAt { get; set; }
        public string Source { get; set; } = string.Empty;
    }
}
