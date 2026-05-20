namespace Domain.Dto.User
{
    public class UserCreateDto
    {
        public string? Phone { get; set; }
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}
