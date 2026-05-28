namespace HealthApp.IntegrationTests.Infrastructure;

internal sealed class ValidationErrorResponse
{
    public string? Message { get; set; }
    public string? UiMessage { get; set; }
    public Dictionary<string, string[]> Errors { get; set; } = new(StringComparer.Ordinal);
}
