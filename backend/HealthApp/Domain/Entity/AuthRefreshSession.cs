using Data.Interfaces;
using Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Domain.Entity
{
    [Table("auth_refresh_sessions")]
    public class AuthRefreshSession : IHasId, IHasAuditDates
    {
        [Key]
        public Guid Id { get; set; }

        public Guid UserId { get; set; }

        [Required]
        [MaxLength(128)]
        public string RefreshTokenHash { get; set; } = string.Empty;

        public AuthProvider Provider { get; set; }

        [MaxLength(120)]
        public string? DeviceId { get; set; }

        [MaxLength(200)]
        public string? DeviceName { get; set; }

        public DateTime ExpiresAt { get; set; }
        public DateTime? RevokedAt { get; set; }
        public DateTime? LastUsedAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }

        [ForeignKey(nameof(UserId))]
        [InverseProperty(nameof(Entity.User.AuthRefreshSessions))]
        public User? User { get; set; }
    }
}
