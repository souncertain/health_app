namespace Services.Interfaces
{
    public interface IAbstractService<T, TDto, TFrontendDto>
    {
        Task<List<TFrontendDto>> GetAll(CancellationToken ct);
        Task<TFrontendDto> GetById(Guid id, CancellationToken ct);
        Task<TFrontendDto> Create(TDto dto, CancellationToken ct);
        Task<TFrontendDto> Update(Guid id, TDto dto, CancellationToken ct);
        Task<bool> Delete(Guid id, CancellationToken ct);
    }
}
