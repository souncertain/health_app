using Enums;

namespace Domain.Dto.HealthMetric
{
    public class HealthMetricCreateDto
    {
        public Guid UserId { get; set; }
        public string Title { get; set; }
        public string Unit { get; set; }
        public double TargetMin { get; set; }
        public double TargetMax { get; set; }
        public MetricVisualStyle VisualStyle { get; set; }
    }
}
