namespace Domain.Dto.Profile
{
    public class ProfilePageUpdateDto
    {
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? Phone { get; set; }
        public string? Gender { get; set; }
        public DateTime? Birthday { get; set; }
        public int? Age { get; set; }
        public string? BloodType { get; set; }
        public int? HeightCm { get; set; }
        public double? WeightKg { get; set; }
        public string? PrimaryDoctor { get; set; }
        public string? EmergencyContactName { get; set; }
        public string? EmergencyContactDetails { get; set; }
        public bool NotificationsEnabled { get; set; } = true;
    }
}
