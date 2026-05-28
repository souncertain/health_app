namespace Services.Interfaces
{
    public interface IAccountEmailSender
    {
        Task SendEmailConfirmationCode(string toEmail, string code, TimeSpan lifetime, CancellationToken ct);
        Task SendPasswordResetCode(string toEmail, string code, TimeSpan lifetime, CancellationToken ct);
    }
}
