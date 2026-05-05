namespace Domain.Dto.MetricRecords
{
    public class MetricRecordDetailsDto
    {
        public Guid Id { get; set; }
        public Guid HealthMetricId { get; set; }
        public double Value { get; set; }
        public DateTime RecordedOn { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }
    }
}
