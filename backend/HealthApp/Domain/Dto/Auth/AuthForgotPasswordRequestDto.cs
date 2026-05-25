using System.ComponentModel.DataAnnotations;

namespace Domain.Dto.Auth
{
    public class AuthForgotPasswordRequestDto
    {
        [Required]
        [EmailAddress]
        [MaxLength(255)]
        public string Email { get; set; } = string.Empty;
    }
}
