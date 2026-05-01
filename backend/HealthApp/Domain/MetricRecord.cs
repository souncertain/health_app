using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Domain
{
    [Table("metric_records")]
    public class MetricRecord
    {
        [Key]
        public Guid Id { get; set; }
        public Guid HealthMetricId { get; set; }
        public double Value { get; set; }
        public DateTime RecordedOn { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }

        [ForeignKey(nameof(HealthMetricId))]
        [InverseProperty(nameof(Domain.HealthMetric.Records))]
        public HealthMetric? HealthMetric { get; set; }
    }
}
