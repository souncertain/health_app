namespace Domain.Dto.Ai
{
    public class DoctorNoteScanResultDto
    {
        public string Category { get; set; } = "unknown";

        public string RawText { get; set; } = string.Empty;
        public string Summary { get; set; } = string.Empty;
        public List<string> Warnings { get; set; } = new();
        public List<DoctorNoteMedicationCandidateDto> Medications { get; set; } = new();
        public List<DoctorNoteVisitCandidateDto> Visits { get; set; } = new();
    }
}
