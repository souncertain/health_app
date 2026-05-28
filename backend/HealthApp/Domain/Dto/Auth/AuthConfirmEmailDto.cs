namespace Domain.Dto.Auth
{
    public class AuthConfirmEmailDto
    {
        public string Email { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
        public string? DeviceId { get; set; }
        public string? DeviceName { get; set; }
    }
}
