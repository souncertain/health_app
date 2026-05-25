namespace Domain.Dto.Ai
{
    public class DoctorNoteMedicationCandidateDto
    {
        public string Name { get; set; } = string.Empty;
        public string DosageText { get; set; } = string.Empty;
        public string FrequencyText { get; set; } = string.Empty;
        public string Instructions { get; set; } = string.Empty;
        public string Note { get; set; } = string.Empty;
    }
}
