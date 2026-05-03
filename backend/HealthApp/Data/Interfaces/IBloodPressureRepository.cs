using Domain.Entity;

namespace Data.Interfaces
{
    public interface IBloodPressureRepository
    {
        Task<List<BloodPressure>> GetAll(CancellationToken ct);
    }
}
