using System.ComponentModel.DataAnnotations;

namespace Domain.Dto.Auth
{
    public class AuthYandexSignInDto
    {
        [Required]
        public string AccessToken { get; set; } = string.Empty;

        [MaxLength(120)]
        public string? DeviceId { get; set; }

        [MaxLength(200)]
        public string? DeviceName { get; set; }
    }
}
