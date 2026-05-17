using Enums;

namespace Domain.Dto.Profile
{
    public class ProfileCreateDto
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public Guid UserId { get; set; }
        public DateTime? Birthday { get; set; }
        public Sex? Sex { get; set; }
        public string? AvatarUrl { get; set; }
        public double? Height { get; set; }
        public double? Weight { get; set; }
        public BloodType? BloodType { get; set; }
        public bool? ResusPhactor { get; set; }
        public string? PrimaryDoctor { get; set; }
        public string? EmergencyContactName { get; set; }
        public string? EmergencyContactDetails { get; set; }
        public bool? NotificationsEnabled { get; set; }
    }
}
