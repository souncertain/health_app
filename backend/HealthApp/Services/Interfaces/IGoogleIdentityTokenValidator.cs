using Domain.Dto.Auth;

namespace Services.Interfaces
{
    public interface IGoogleIdentityTokenValidator
    {
        Task<ExternalIdentityProfileDto> Validate(string idToken, CancellationToken ct);
    }
}
