using FluentValidation;

namespace Services.Validation.Infrastructure
{
    public class RequestValidationService : IRequestValidationService
    {
        private readonly IServiceProvider _serviceProvider;

        public RequestValidationService(IServiceProvider serviceProvider)
        {
            _serviceProvider = serviceProvider;
        }

        public async Task ValidateAndThrowAsync<TModel>(TModel model, CancellationToken ct = default)
        {
            if (model is null)
            {
                throw new ArgumentNullException(nameof(model));
            }

            var validator = _serviceProvider.GetService(typeof(IValidator<TModel>)) as IValidator<TModel>;
            if (validator is null)
            {
                return;
            }

            await validator.ValidateAndThrowAsync(model, ct);
        }
    }
}
