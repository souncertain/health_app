namespace HealthApp.Configuration
{
    public class EmailOptions
    {
        public const string SectionName = "Email";

        public string Mode { get; set; } = "PickupDirectory";
        public string FromAddress { get; set; } = "no-reply@healthtrack.local";
        public string FromName { get; set; } = "HealthTrack";
        public string PickupDirectoryPath { get; set; } = "artifacts/mail-drop";
        public SmtpOptions Smtp { get; set; } = new();
    }

    public class SmtpOptions
    {
        public string Host { get; set; } = string.Empty;
        public int Port { get; set; } = 587;
        public bool EnableSsl { get; set; } = true;
        public string? Username { get; set; }
        public string? Password { get; set; }
    }
}
