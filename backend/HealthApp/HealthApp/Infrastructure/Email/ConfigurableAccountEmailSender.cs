using HealthApp.Configuration;
using Microsoft.Extensions.Options;
using Services.Interfaces;
using System.Net;
using System.Net.Mail;
using System.Text;

namespace HealthApp.Infrastructure.Email
{
    public class ConfigurableAccountEmailSender : IAccountEmailSender
    {
        private readonly EmailOptions _options;
        private readonly ILogger<ConfigurableAccountEmailSender> _logger;
        private readonly IWebHostEnvironment _environment;

        public ConfigurableAccountEmailSender(
            IOptions<EmailOptions> emailOptions,
            ILogger<ConfigurableAccountEmailSender> logger,
            IWebHostEnvironment environment)
        {
            _options = emailOptions.Value ?? new EmailOptions();
            _logger = logger;
            _environment = environment;
        }

        public Task SendPasswordResetCode(string toEmail, string code, TimeSpan lifetime, CancellationToken ct)
        {
            var roundedMinutes = Math.Max(1, (int)Math.Ceiling(lifetime.TotalMinutes));
            var subject = "HealthTrack password reset code";
            var body = $"""
                Your HealthTrack password reset code is: {code}

                This code expires in {roundedMinutes} minute(s).
                If you did not request a password reset, you can ignore this email.
                """;

            return SendMessage(toEmail, subject, body, ct);
        }

        public Task SendEmailConfirmationCode(string toEmail, string code, TimeSpan lifetime, CancellationToken ct)
        {
            var roundedMinutes = Math.Max(1, (int)Math.Ceiling(lifetime.TotalMinutes));
            var subject = "HealthTrack email confirmation code";
            var body = $"""
                Confirm your email for HealthTrack using this code: {code}

                This code expires in {roundedMinutes} minute(s).
                If you did not create an account, you can ignore this email.
                """;

            return SendMessage(toEmail, subject, body, ct);
        }

        private async Task SendMessage(string toEmail, string subject, string body, CancellationToken ct)
        {
            if (string.Equals(_options.Mode, "Smtp", StringComparison.OrdinalIgnoreCase))
            {
                await SendViaSmtp(toEmail, subject, body, ct);
                return;
            }

            await SaveToPickupDirectory(toEmail, subject, body, ct);
        }

        private async Task SendViaSmtp(string toEmail, string subject, string body, CancellationToken ct)
        {
            if (string.IsNullOrWhiteSpace(_options.Smtp.Host))
            {
                throw new InvalidOperationException("Email:Smtp:Host must be configured for SMTP delivery.");
            }

            using var message = new MailMessage
            {
                From = new MailAddress(_options.FromAddress, _options.FromName, Encoding.UTF8),
                Subject = subject,
                Body = body,
                SubjectEncoding = Encoding.UTF8,
                BodyEncoding = Encoding.UTF8,
                IsBodyHtml = false
            };
            message.To.Add(new MailAddress(toEmail));

            using var client = new SmtpClient(_options.Smtp.Host, _options.Smtp.Port)
            {
                EnableSsl = _options.Smtp.EnableSsl,
                DeliveryMethod = SmtpDeliveryMethod.Network
            };

            if (!string.IsNullOrWhiteSpace(_options.Smtp.Username))
            {
                client.Credentials = new NetworkCredential(
                    _options.Smtp.Username,
                    _options.Smtp.Password ?? string.Empty);
            }

            await client.SendMailAsync(message, ct);
        }

        private async Task SaveToPickupDirectory(string toEmail, string subject, string body, CancellationToken ct)
        {
            var configuredPath = _options.PickupDirectoryPath?.Trim();
            var relativePath = string.IsNullOrWhiteSpace(configuredPath)
                ? Path.Combine("artifacts", "mail-drop")
                : configuredPath;

            var directory = Path.IsPathRooted(relativePath)
                ? relativePath
                : Path.Combine(_environment.ContentRootPath, relativePath);

            Directory.CreateDirectory(directory);

            var fileName = $"{DateTime.UtcNow:yyyyMMddHHmmssfff}-{Guid.NewGuid():N}.txt";
            var fullPath = Path.Combine(directory, fileName);
            var content = $"""
                To: {toEmail}
                From: {_options.FromName} <{_options.FromAddress}>
                Subject: {subject}
                SentUtc: {DateTime.UtcNow:O}

                {body}
                """;

            await File.WriteAllTextAsync(fullPath, content, Encoding.UTF8, ct);
            _logger.LogInformation("Account email saved to pickup directory at {Path}", fullPath);
        }
    }
}
