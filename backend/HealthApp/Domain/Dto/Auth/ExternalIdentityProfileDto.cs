using Enums;

namespace Domain.Dto.Auth
{
    public class ExternalIdentityProfileDto
    {
        public AuthProvider Provider { get; set; }
        public string ProviderUserId { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public bool EmailVerified { get; set; }
    }
}
