namespace Domain.Dto.Profile
{
    public class ProfilePageDto
    {
        public Guid Id { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Gender { get; set; } = "unspecified";
        public int? Age { get; set; }
        public string? BloodType { get; set; }
        public int? HeightCm { get; set; }
        public double? WeightKg { get; set; }
        public string? PrimaryDoctor { get; set; }
        public string? EmergencyContactName { get; set; }
        public string? EmergencyContactDetails { get; set; }
        public bool NotificationsEnabled { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public ProfileStatsDto Stats { get; set; } = new();
    }
}
