namespace HealthApp.Configuration
{
    public class DoctorNoteScannerOptions
    {
        public const string SectionName = "DoctorNoteScanner";

        public bool Enabled { get; set; } = false;
        public string Provider { get; set; } = "OpenAI";
        public int MaxImageBytes { get; set; } = 8 * 1024 * 1024;
        public OpenAiDoctorNoteScannerOptions OpenAI { get; set; } = new();
    }

    public class OpenAiDoctorNoteScannerOptions
    {
        public string ApiKey { get; set; } = string.Empty;
        public string Endpoint { get; set; } = "https://api.openai.com/v1/responses";
        public string Model { get; set; } = "gpt-4.1";
        public int RequestTimeoutSeconds { get; set; } = 60;
    }
}
