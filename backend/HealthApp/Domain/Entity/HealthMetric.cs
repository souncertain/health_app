using Data.Interfaces;
using Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Domain.Entity
{
    [Table("health_metrics")]
    public class HealthMetric : IHasId, IUserOwnedEntity, IHasAuditDates
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
        [InverseProperty(nameof(Entity.User.HealthMetrics))]
        public User? User { get; set; }

        [InverseProperty(nameof(MetricRecord.HealthMetric))]
        public ICollection<MetricRecord> Records { get; set; } = new List<MetricRecord>();
    }
}
