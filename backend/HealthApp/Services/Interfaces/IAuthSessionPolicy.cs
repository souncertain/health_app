namespace Services.Interfaces
{
    public interface IAuthSessionPolicy
    {
        TimeSpan RefreshTokenLifetime { get; }
        bool UseSlidingRefreshExpiration { get; }
    }
}
