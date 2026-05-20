using Domain.Entity;
using Enums;
using HealthApp.Configuration;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using Services.Interfaces;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace HealthApp.Infrastructure.Auth
{
    public class JwtTokenFactory : IJwtTokenFactory
    {
        private readonly IOptions<AuthOptions> _authOptions;

        public JwtTokenFactory(IOptions<AuthOptions> authOptions)
        {
            _authOptions = authOptions;
        }

        public (string Token, DateTime ExpiresAtUtc) CreateAccessToken(User user, AuthProvider provider, string displayName)
        {
            var jwtOptions = _authOptions.Value.Jwt;
            var expiresAtUtc = DateTime.UtcNow.AddMinutes(Math.Max(1, jwtOptions.AccessTokenLifetimeMinutes));
            var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtOptions.SigningKey));
            var credentials = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new(ClaimTypes.Email, user.Email),
                new(ClaimTypes.Name, displayName),
                new("provider", provider.ToString().ToLowerInvariant())
            };

            var descriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Issuer = jwtOptions.Issuer,
                Audience = jwtOptions.Audience,
                Expires = expiresAtUtc,
                SigningCredentials = credentials
            };

            var handler = new JwtSecurityTokenHandler();
            var token = handler.CreateToken(descriptor);
            return (handler.WriteToken(token), expiresAtUtc);
        }
    }
}
