using System.ComponentModel.DataAnnotations;

namespace Domain.Dto.Auth
{
    public class AuthGoogleSignInDto
    {
        [Required]
        public string IdToken { get; set; } = string.Empty;

        [MaxLength(120)]
        public string? DeviceId { get; set; }

        [MaxLength(200)]
        public string? DeviceName { get; set; }
    }
}
