namespace Data.Interfaces
{
    public interface IAbstractRepository<T>
    {
        Task<List<T>> GetAll(CancellationToken ct = default);
        Task<T?> GetById(Guid id, CancellationToken ct = default);
        Task Create(T entity, CancellationToken ct = default);
        Task Update(T entity, CancellationToken ct = default);
        Task Delete(T entity, CancellationToken ct = default);
        Task Save(CancellationToken ct = default);
    }
}
