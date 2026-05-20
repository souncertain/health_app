using Domain.Dto.Auth;
using Domain.Exceptions;
using Enums;
using Google.Apis.Auth;
using HealthApp.Configuration;
using Microsoft.Extensions.Options;
using Services.Interfaces;
using System.Net;

namespace HealthApp.Infrastructure.Auth
{
    public class GoogleIdentityTokenValidator : IGoogleIdentityTokenValidator
    {
        private readonly IOptions<AuthOptions> _authOptions;

        public GoogleIdentityTokenValidator(IOptions<AuthOptions> authOptions)
        {
            _authOptions = authOptions;
        }

        public async Task<ExternalIdentityProfileDto> Validate(string idToken, CancellationToken ct)
        {
            var clientIds = _authOptions.Value.Google.AllowedClientIds
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .Distinct(StringComparer.Ordinal)
                .ToList();

            if (clientIds.Count == 0)
            {
                throw new AuthException("Google auth не настроен на backend.", HttpStatusCode.InternalServerError);
            }

            GoogleJsonWebSignature.Payload payload;
            try
            {
                payload = await GoogleJsonWebSignature.ValidateAsync(idToken, new GoogleJsonWebSignature.ValidationSettings
                {
                    Audience = clientIds
                });
            }
            catch (InvalidJwtException)
            {
                throw new AuthException("Недействительный Google id token.", HttpStatusCode.Unauthorized);
            }

            if (string.IsNullOrWhiteSpace(payload.Subject))
            {
                throw new AuthException("Google не вернул идентификатор пользователя.", HttpStatusCode.Unauthorized);
            }

            if (string.IsNullOrWhiteSpace(payload.Email))
            {
                throw new AuthException("Google не вернул email пользователя.", HttpStatusCode.Unauthorized);
            }

            return new ExternalIdentityProfileDto
            {
                Provider = AuthProvider.Google,
                ProviderUserId = payload.Subject,
                Email = payload.Email,
                DisplayName = payload.Name ?? payload.GivenName ?? payload.Email,
                EmailVerified = payload.EmailVerified
            };
        }
    }
}
