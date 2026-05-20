namespace Data.Interfaces
{
    public interface IHasAuditDates
    {
        DateTime CreatedAt { get; set; }
        DateTime LastUpdatedAt { get; set; }
    }
}
