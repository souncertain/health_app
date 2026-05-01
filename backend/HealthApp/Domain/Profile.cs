using Enums;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Domain
{
    [Table("profiles")]
    public class Profile
    {
        [Key]
        public Guid Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string LastName { get; set; } = string.Empty;
        public Guid UserId { get; set; }
        public DateTime Birthday { get; set; }

        public Sex Sex { get; set; }

        [MaxLength(2048)]
        public string AvatarUrl { get; set; } = string.Empty;

        [Range(30, 300)]
        public double Height { get; set; }

        [Range(1, 700)]
        public double Weight { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime LastUpdatedAt { get; set; }
        public BloodType BloodType { get; set; }
        public bool ResusPhactor { get; set; }
        [ForeignKey(nameof(UserId))]
        [InverseProperty(nameof(Domain.User.Profile))]
        public User? User { get; set; }
    }
}
