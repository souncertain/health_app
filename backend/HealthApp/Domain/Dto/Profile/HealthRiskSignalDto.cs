namespace Domain.Dto.Profile
{
    public class HealthRiskSignalDto
    {
        public string Key { get; set; } = string.Empty;

        public string Level { get; set; } = "info";

        public string Title { get; set; } = string.Empty;

        public string Description { get; set; } = string.Empty;
    }
}
