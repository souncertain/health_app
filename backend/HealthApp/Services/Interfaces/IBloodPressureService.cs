using Domain.Entity;

namespace Services.Interfaces
{
    public interface IBloodPressureService
    {
        Task<List<BloodPressure>> GetAll(CancellationToken ct);
    }
}
