namespace Services.Interfaces
{
    public interface IPasswordResetPolicy
    {
        int CodeLength { get; }
        int MaxAttempts { get; }
        TimeSpan CodeLifetime { get; }
        TimeSpan ResendCooldown { get; }
    }
}
