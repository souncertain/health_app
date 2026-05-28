namespace Domain.Dto.Auth
{
    public class AuthCurrentUserDto
    {
        public string UserId { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public bool EmailConfirmed { get; set; }
        public List<string> LinkedProviders { get; set; } = new();
        public bool HasPassword { get; set; }
    }
}
