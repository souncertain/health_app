using Domain.Dto.Auth;
using Domain.Exceptions;
using Enums;
using HealthApp.Configuration;
using Microsoft.Extensions.Options;
using Services.Interfaces;
using System.Net;
using System.Net.Http.Headers;
using System.Text.Json.Serialization;

namespace HealthApp.Infrastructure.Auth
{
    public class YandexIdentityProviderClient : IYandexIdentityProviderClient
    {
        private readonly HttpClient _httpClient;
        private readonly IOptions<AuthOptions> _authOptions;

        public YandexIdentityProviderClient(HttpClient httpClient, IOptions<AuthOptions> authOptions)
        {
            _httpClient = httpClient;
            _authOptions = authOptions;
        }

        public async Task<ExternalIdentityProfileDto> GetProfile(string accessToken, CancellationToken ct)
        {
            var options = _authOptions.Value.Yandex;
            if (string.IsNullOrWhiteSpace(options.ClientId))
            {
                throw new AuthException("Yandex auth не настроен на backend.", HttpStatusCode.InternalServerError);
            }

            using var request = new HttpRequestMessage(HttpMethod.Get, $"{options.UserInfoEndpoint}?format=json");
            request.Headers.Authorization = new AuthenticationHeaderValue("OAuth", accessToken);

            using var response = await _httpClient.SendAsync(request, ct);
            if (response.StatusCode == HttpStatusCode.Unauthorized || response.StatusCode == HttpStatusCode.Forbidden)
            {
                throw new AuthException("Недействительный Yandex access token.", HttpStatusCode.Unauthorized);
            }

            if (!response.IsSuccessStatusCode)
            {
                throw new AuthException("Не удалось получить профиль Yandex.", HttpStatusCode.BadGateway);
            }

            var payload = await response.Content.ReadFromJsonAsync<YandexUserInfoResponse>(cancellationToken: ct);
            if (payload is null || string.IsNullOrWhiteSpace(payload.Id))
            {
                throw new AuthException("Yandex не вернул идентификатор пользователя.", HttpStatusCode.Unauthorized);
            }

            if (!string.IsNullOrWhiteSpace(payload.ClientId) &&
                !string.Equals(payload.ClientId, options.ClientId, StringComparison.Ordinal))
            {
                throw new AuthException("Yandex access token выпущен для другого client id.", HttpStatusCode.Unauthorized);
            }

            var email = payload.DefaultEmail?.Trim();
            if (string.IsNullOrWhiteSpace(email))
            {
                throw new AuthException("Yandex не вернул email пользователя. Проверьте scope login:email.", HttpStatusCode.Unauthorized);
            }

            var displayName = payload.RealName?.Trim();
            if (string.IsNullOrWhiteSpace(displayName))
            {
                displayName = payload.DisplayName?.Trim();
            }
            if (string.IsNullOrWhiteSpace(displayName))
            {
                displayName = payload.Login?.Trim();
            }
            if (string.IsNullOrWhiteSpace(displayName))
            {
                displayName = email;
            }

            return new ExternalIdentityProfileDto
            {
                Provider = AuthProvider.Yandex,
                ProviderUserId = payload.Id,
                Email = email,
                DisplayName = displayName,
                EmailVerified = true
            };
        }

        private sealed class YandexUserInfoResponse
        {
            [JsonPropertyName("id")]
            public string? Id { get; set; }

            [JsonPropertyName("client_id")]
            public string? ClientId { get; set; }

            [JsonPropertyName("login")]
            public string? Login { get; set; }

            [JsonPropertyName("display_name")]
            public string? DisplayName { get; set; }

            [JsonPropertyName("real_name")]
            public string? RealName { get; set; }

            [JsonPropertyName("default_email")]
            public string? DefaultEmail { get; set; }
        }
    }
}
