using Services.Interfaces;
using System.Security.Cryptography;
using System.Text;

namespace HealthApp.Infrastructure.Auth
{
    public class RefreshTokenFactory : IRefreshTokenFactory
    {
        public string CreateToken()
        {
            Span<byte> buffer = stackalloc byte[32];
            RandomNumberGenerator.Fill(buffer);
            return Convert.ToBase64String(buffer)
                .TrimEnd('=')
                .Replace('+', '-')
                .Replace('/', '_');
        }

        public string HashToken(string token)
        {
            var bytes = Encoding.UTF8.GetBytes(token);
            var hash = SHA256.HashData(bytes);
            return Convert.ToHexString(hash);
        }
    }
}
