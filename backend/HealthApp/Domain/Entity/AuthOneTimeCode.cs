using Data.Interfaces;
using Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Domain.Entity
{
    [Table("auth_one_time_codes")]
    public class AuthOneTimeCode : IHasId, IHasAuditDates
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        public Guid UserId { get; set; }

        [ForeignKey(nameof(UserId))]
        public User? User { get; set; }

        [Required]
        [MaxLength(255)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public AuthOneTimeCodePurpose Purpose { get; set; }

        [Required]
        [MaxLength(128)]
        public string CodeHash { get; set; } = string.Empty;

        [Required]
        public DateTime ExpiresAt { get; set; }

        public DateTime? UsedAt { get; set; }
        public DateTime? InvalidatedAt { get; set; }

        [Range(0, int.MaxValue)]
        public int FailedAttemptCount { get; set; }

        [Range(1, 20)]
        public int MaxAllowedAttempts { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }
    }
}
