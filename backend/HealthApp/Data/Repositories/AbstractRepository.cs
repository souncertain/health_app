using Data.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Data.Repositories
{
    public abstract class AbstractRepository<T> : IAbstractRepository<T> where T : class, IHasId
    {
        protected readonly HealthAppDbContext _context;
        public AbstractRepository(HealthAppDbContext context)
        {
            _context = context;
        }

        public async Task<List<T>> GetAll(CancellationToken ct = default)
        {
            return await _context.Set<T>()
                .AsNoTracking()
                .ToListAsync(ct);
        }

        public async Task<T?> GetById(Guid id, CancellationToken ct = default)
        {
            return await _context.Set<T>()
                .Where(x => x.Id == id)
                    .FirstOrDefaultAsync(ct);
        }
        public async Task Create(T entity, CancellationToken ct = default)
        {
            _context.Set<T>().Add(entity);
        }
        public async Task Update(T entity, CancellationToken ct = default)
        {
            _context.Set<T>().Update(entity);
        }

        public async Task Delete(T entity, CancellationToken ct = default)
        {
            _context.Set<T>().Remove(entity);
        }

        public async Task Save(CancellationToken ct = default)
        {
            await _context.SaveChangesAsync(ct);
        }
    }
}
