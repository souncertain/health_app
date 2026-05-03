using Services.Interfaces;
using Data.Interfaces;
using Domain.Entity;

namespace Services
{
    public class BloodPressureService : IBloodPressureService
    {
        private readonly IBloodPressureRepository _repository;
        public BloodPressureService(IBloodPressureRepository repository) 
        {
            _repository = repository;
        }
        public async Task<List<BloodPressure>> GetAll(CancellationToken ct)
        {
            return await _repository.GetAll(ct);
        }
    }
}
