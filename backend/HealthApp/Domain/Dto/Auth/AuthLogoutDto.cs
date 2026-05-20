using System.ComponentModel.DataAnnotations;

namespace Domain.Dto.Auth
{
    public class AuthLogoutDto
    {
        [Required]
        public string RefreshSessionId { get; set; } = string.Empty;

        [Required]
        public string RefreshToken { get; set; } = string.Empty;
    }
}
