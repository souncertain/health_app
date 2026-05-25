namespace Services.Interfaces
{
    public interface IAccountEmailSender
    {
        Task SendPasswordResetCode(string toEmail, string code, TimeSpan lifetime, CancellationToken ct);
    }
}
