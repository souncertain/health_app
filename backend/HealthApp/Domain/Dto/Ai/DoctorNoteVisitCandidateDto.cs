namespace Domain.Dto.Ai
{
    public class DoctorNoteVisitCandidateDto
    {
        public string DoctorName { get; set; } = string.Empty;
        public string Specialty { get; set; } = string.Empty;
        public string DateText { get; set; } = string.Empty;
        public string TimeText { get; set; } = string.Empty;
        public string Location { get; set; } = string.Empty;
        public string Note { get; set; } = string.Empty;
    }
}
