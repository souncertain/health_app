using Services.Validation.Infrastructure;

namespace HealthApp.UnitTests.TestDoubles;

public sealed class TrackingValidationService : IRequestValidationService
{
    public List<object> ValidatedModels { get; } = new();

    public Exception? ExceptionToThrow { get; set; }

    public Task ValidateAndThrowAsync<TModel>(TModel model, CancellationToken ct = default)
    {
        if (model is not null)
        {
            ValidatedModels.Add(model);
        }

        if (ExceptionToThrow is not null)
        {
            throw ExceptionToThrow;
        }

        return Task.CompletedTask;
    }
}
