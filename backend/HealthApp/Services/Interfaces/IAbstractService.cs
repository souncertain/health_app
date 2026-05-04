namespace Services.Interfaces
{
    public interface IAbstractService<T, TDto, TFrontendDto>
    {
        Task<List<TFrontendDto>> GetAll(CancellationToken ct);
        Task<TFrontendDto> Create(TDto dto, CancellationToken ct);
    }
}
