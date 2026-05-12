namespace Domain.Dto.Medication
{
    public class MedicationStatusesDto
    {
        public int TakenCount { get; set; }
        public int PendingCount { get; set; }
        public int MissedCount { get; set; }
    }
}
