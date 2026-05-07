using Data.Interfaces;
using Domain.Entity;
using Microsoft.EntityFrameworkCore;

namespace Data.Repositories
{
    public class BloodPressureRepository : AbstractRepository<BloodPressure> , IBloodPressureRepository 
    {
        public BloodPressureRepository(HealthAppDbContext context) : base(context)
        {
        }
        public async Task <IEnumerable<BloodPressure>> GetByDateInterval(int interval)
        {
            var endDate = DateTime.UtcNow;
            var startDate = endDate.AddDays(interval * -1);
            return await _context.Set<BloodPressure>()
                .Where(x => x.RecordedAt <= endDate && x.RecordedAt >= startDate)
                .Take(30)
                .ToListAsync();
        }

        public async Task<(int Systolic, int Diastolic, int Pulse)> GetAverageValues()
        {
            var list = await _context.Set<BloodPressure>().ToListAsync();
            if (list.Count == 0) return (0, 0, 0);
            var systolic = list.Select(x => x.Systolic).Average();
            var diastolic = list.Select(x => x.Diastolic).Average();
            var pulse = list.Select(x => x.Pulse).Average();

            return ((int)systolic, (int)diastolic, (int)pulse);
        }

        public async Task<IEnumerable<BloodPressure>> GetLastValues(int last)
        {
            return await _context.Set<BloodPressure>().Take(last).ToListAsync();
        }
    }
}
