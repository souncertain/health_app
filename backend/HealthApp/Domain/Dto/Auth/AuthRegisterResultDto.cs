namespace Domain.Dto.Auth
{
    public class AuthRegisterResultDto
    {
        public string Email { get; set; } = string.Empty;
        public bool EmailConfirmationRequired { get; set; } = true;
    }
}
