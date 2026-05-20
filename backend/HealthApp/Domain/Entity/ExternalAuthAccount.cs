using Data.Interfaces;
using Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Domain.Entity
{
    [Table("external_auth_accounts")]
    public class ExternalAuthAccount : IHasId, IHasAuditDates
    {
        [Key]
        public Guid Id { get; set; }

        public Guid UserId { get; set; }

        public AuthProvider Provider { get; set; }

        [Required]
        [MaxLength(255)]
        public string ProviderUserId { get; set; } = string.Empty;

        [MaxLength(255)]
        [EmailAddress]
        public string? Email { get; set; }

        [MaxLength(255)]
        public string? DisplayName { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }

        [ForeignKey(nameof(UserId))]
        [InverseProperty(nameof(Entity.User.ExternalAuthAccounts))]
        public User? User { get; set; }
    }
}
