using Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Domain
{
    [Table("health_metrics")]
    public class HealthMetric
    {
        [Key]
        public Guid Id { get; set; }
        public Guid UserId { get; set; }

        [Required]
        [MaxLength(100)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [MaxLength(30)]
        public string Unit { get; set; } = string.Empty;

        public double TargetMin { get; set; }
        public double TargetMax { get; set; }
        public MetricVisualStyle VisualStyle { get; set; }
        public bool IsCustom { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }

        [ForeignKey(nameof(UserId))]
        [InverseProperty(nameof(Domain.User.HealthMetrics))]
        public User? User { get; set; }

        [InverseProperty(nameof(Domain.MetricRecord.HealthMetric))]
        public ICollection<MetricRecord> Records { get; set; } = new List<MetricRecord>();
    }
}
