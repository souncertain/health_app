using System.ComponentModel.DataAnnotations;

namespace Domain.Dto.Auth
{
    public class AuthResetPasswordDto
    {
        [Required]
        [EmailAddress]
        [MaxLength(255)]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MaxLength(32)]
        public string Code { get; set; } = string.Empty;

        [Required]
        [MinLength(6)]
        [MaxLength(200)]
        public string NewPassword { get; set; } = string.Empty;
    }
}
