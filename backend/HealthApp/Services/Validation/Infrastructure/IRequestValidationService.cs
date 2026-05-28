namespace Services.Validation.Infrastructure
{
    public interface IRequestValidationService
    {
        Task ValidateAndThrowAsync<TModel>(TModel model, CancellationToken ct = default);
    }
}
