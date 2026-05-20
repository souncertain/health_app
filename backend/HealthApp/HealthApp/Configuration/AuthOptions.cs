namespace HealthApp.Configuration
{
    public class AuthOptions
    {
        public const string SectionName = "Auth";

        public JwtOptions Jwt { get; set; } = new();
        public RefreshTokenOptions RefreshTokens { get; set; } = new();
        public GoogleAuthOptions Google { get; set; } = new();
        public YandexAuthOptions Yandex { get; set; } = new();
    }

    public class JwtOptions
    {
        public string Issuer { get; set; } = "HealthApp";
        public string Audience { get; set; } = "health-app-mobile";
        public string SigningKey { get; set; } = string.Empty;
        public int AccessTokenLifetimeMinutes { get; set; } = 15;
        public int ClockSkewMinutes { get; set; } = 2;
    }

    public class RefreshTokenOptions
    {
        public int LifetimeHours { get; set; } = 24;
        public bool UseSlidingExpiration { get; set; } = true;
    }

    public class GoogleAuthOptions
    {
        public List<string> AllowedClientIds { get; set; } = new();
    }

    public class YandexAuthOptions
    {
        public string ClientId { get; set; } = string.Empty;
        public string? ClientSecret { get; set; }
        public string UserInfoEndpoint { get; set; } = "https://login.yandex.ru/info";
    }
}
