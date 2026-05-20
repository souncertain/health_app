using System.ComponentModel.DataAnnotations;

namespace Domain.Dto.Auth
{
    public class AuthRegisterDto
    {
        [Required]
        [EmailAddress]
        [MaxLength(255)]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MinLength(6)]
        [MaxLength(200)]
        public string Password { get; set; } = string.Empty;

        [MaxLength(20)]
        public string? Phone { get; set; }

        [MaxLength(120)]
        public string? DeviceId { get; set; }

        [MaxLength(200)]
        public string? DeviceName { get; set; }
    }
}
