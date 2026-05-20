namespace Domain.Dto.Auth
{
    public class AuthSessionDto
    {
        public string UserId { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Provider { get; set; } = string.Empty;
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
        public DateTime IssuedAt { get; set; }
        public DateTime? AccessTokenExpiresAt { get; set; }
        public string? RefreshSessionId { get; set; }
    }
}
