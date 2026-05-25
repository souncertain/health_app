using Data.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Data.Repositories
{
    public abstract class AbstractRepository<T> : IAbstractRepository<T> where T : class, IHasId
    {
        protected readonly HealthAppDbContext _context;
        private readonly ICurrentUserContext _currentUserContext;

        protected Guid? CurrentUserId => _currentUserContext.UserId;

        public AbstractRepository(HealthAppDbContext context, ICurrentUserContext currentUserContext)
        {
            _context = context;
            _currentUserContext = currentUserContext;
        }

        protected IQueryable<T> Query(bool asNoTracking = false)
        {
            IQueryable<T> query = _context.Set<T>();
            if (asNoTracking)
            {
                query = query.AsNoTracking();
            }

            return ApplyCurrentUserScope(query);
        }

        protected IQueryable<TEntity> ApplyCurrentUserScope<TEntity>(IQueryable<TEntity> query)
            where TEntity : class
        {
            if (!_currentUserContext.HasUserId || !typeof(IUserOwnedEntity).IsAssignableFrom(typeof(TEntity)))
            {
                return query;
            }

            var currentUserId = _currentUserContext.UserId!.Value;
            return query.Where(entity =>
                EF.Property<Guid>(entity, nameof(IUserOwnedEntity.UserId)) == currentUserId);
        }

        private void AssignCurrentUserIfOwned(T entity)
        {
            if (!_currentUserContext.HasUserId || entity is not IUserOwnedEntity userOwnedEntity)
            {
                return;
            }

            userOwnedEntity.UserId = _currentUserContext.UserId!.Value;
        }

        private void ApplyAuditDatesOnCreate(T entity)
        {
            if (entity is not IHasAuditDates auditEntity)
            {
                return;
            }

            var now = DateTime.UtcNow;
            if (auditEntity.CreatedAt == default)
            {
                auditEntity.CreatedAt = now;
            }

            auditEntity.LastUpdatedAt = now;
        }

        private void ApplyAuditDatesOnUpdate(T entity, T existingEntity)
        {
            if (entity is not IHasAuditDates incomingAuditEntity ||
                existingEntity is not IHasAuditDates existingAuditEntity)
            {
                return;
            }

            incomingAuditEntity.CreatedAt = existingAuditEntity.CreatedAt;
            incomingAuditEntity.LastUpdatedAt = DateTime.UtcNow;
        }

        public virtual async Task<List<T>> GetAll(CancellationToken ct = default)
        {
            return await Query(asNoTracking: true).ToListAsync(ct);
        }

        public virtual async Task<T?> GetById(Guid id, CancellationToken ct = default)
        {
            return await Query().FirstOrDefaultAsync(x => x.Id == id, ct);
        }

        public virtual Task Create(T entity, CancellationToken ct = default)
        {
            AssignCurrentUserIfOwned(entity);
            ApplyAuditDatesOnCreate(entity);
            _context.Set<T>().Add(entity);
            return Task.CompletedTask;
        }

        public virtual async Task Update(T entity, CancellationToken ct = default)
        {
            var existingEntity = await Query().FirstOrDefaultAsync(x => x.Id == entity.Id, ct);
            if (existingEntity is null)
            {
                throw new InvalidOperationException($"{typeof(T).Name} with id '{entity.Id}' was not found.");
            }

            AssignCurrentUserIfOwned(entity);
            ApplyAuditDatesOnUpdate(entity, existingEntity);
            _context.Entry(existingEntity).CurrentValues.SetValues(entity);
        }

        public virtual async Task Delete(T entity, CancellationToken ct = default)
        {
            var existingEntity = await Query().FirstOrDefaultAsync(x => x.Id == entity.Id, ct);
            if (existingEntity is null)
            {
                return;
            }

            _context.Set<T>().Remove(existingEntity);
        }

        public virtual async Task Save(CancellationToken ct = default)
        {
            await _context.SaveChangesAsync(ct);
        }
    }
}
