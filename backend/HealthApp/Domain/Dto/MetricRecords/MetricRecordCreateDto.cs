namespace Domain.Dto.MetricRecords
{
    public class MetricRecordCreateDto
    {
        public Guid HealthMetricId { get; set; }
        public double Value { get; set; }
        public DateTime RecordedOn { get; set; }
    }
}
