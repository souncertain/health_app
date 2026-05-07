using Domain.Entity;

namespace Data.Interfaces
{
    public interface IBloodPressureRepository : IAbstractRepository<BloodPressure>
    {
        Task<IEnumerable<BloodPressure>> GetByDateInterval(int interval);
        Task<(int Systolic, int Diastolic, int Pulse)> GetAverageValues();
        Task<IEnumerable<BloodPressure>> GetLastValues(int last);
    }
}
