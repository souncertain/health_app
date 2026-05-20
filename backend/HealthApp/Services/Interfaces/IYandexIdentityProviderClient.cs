using Domain.Dto.Auth;

namespace Services.Interfaces
{
    public interface IYandexIdentityProviderClient
    {
        Task<ExternalIdentityProfileDto> GetProfile(string accessToken, CancellationToken ct);
    }
}
