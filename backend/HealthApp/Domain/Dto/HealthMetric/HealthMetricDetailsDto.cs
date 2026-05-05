using Enums;

namespace Domain.Dto.HealthMetric
{
    public class HealthMetricDetailsDto
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string Title { get; set; }
        public string Unit { get; set; }
        public double TargetMin { get; set; }
        public double TargetMax { get; set; }
        public MetricVisualStyle VisualStyle { get; set; }
        public bool IsCustom { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }
    }
}
