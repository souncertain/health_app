using Services.Interfaces;
using System.Security.Cryptography;
using System.Text;

namespace HealthApp.Infrastructure.Auth
{
    public class OneTimeCodeFactory : IOneTimeCodeFactory
    {
        public string CreateNumericCode(int length)
        {
            if (length <= 0)
            {
                throw new ArgumentOutOfRangeException(nameof(length));
            }

            var buffer = new char[length];
            for (var index = 0; index < length; index++)
            {
                buffer[index] = (char)('0' + RandomNumberGenerator.GetInt32(0, 10));
            }

            return new string(buffer);
        }

        public string HashCode(string code)
        {
            var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(code.Trim()));
            return Convert.ToHexString(bytes);
        }
    }
}
