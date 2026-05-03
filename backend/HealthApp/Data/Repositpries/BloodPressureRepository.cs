using Data.Interfaces;
using Domain.Entity;
using Microsoft.EntityFrameworkCore;

namespace Data.Repositpries
{
    public class BloodPressureRepository : IBloodPressureRepository
    {
        private readonly HealthAppDbContext _context;

        public BloodPressureRepository(HealthAppDbContext context)
        {
            _context = context;
        }

        public async Task<List<BloodPressure>> GetAll(CancellationToken ct)
        {
            return await _context.Set<BloodPressure>()
                .AsNoTracking()
                .OrderByDescending(x => x.RecordedAt)
                .ToListAsync(ct);
        }
    }
}
