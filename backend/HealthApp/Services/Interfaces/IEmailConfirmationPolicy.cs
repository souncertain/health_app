namespace Services.Interfaces
{
    public interface IEmailConfirmationPolicy
    {
        int CodeLength { get; }
        int MaxAttempts { get; }
        TimeSpan CodeLifetime { get; }
        TimeSpan ResendCooldown { get; }
    }
}
