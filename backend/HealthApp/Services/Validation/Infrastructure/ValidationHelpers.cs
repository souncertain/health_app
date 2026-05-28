using System.Net.Mail;
using System.Text.RegularExpressions;

namespace Services.Validation.Infrastructure
{
    public static partial class ValidationHelpers
    {
        public static bool HasText(string? value) => !string.IsNullOrWhiteSpace(value);

        public static bool HasMaxTrimmedLength(string? value, int maxLength) =>
            string.IsNullOrWhiteSpace(value) || value.Trim().Length <= maxLength;

        public static bool HasMinTrimmedLength(string? value, int minLength) =>
            !string.IsNullOrWhiteSpace(value) && value.Trim().Length >= minLength;

        public static bool IsValidEmail(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return false;
            }

            return MailAddress.TryCreate(value.Trim(), out _);
        }

        public static bool IsValidPhone(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return true;
            }

            return PhoneRegex().IsMatch(value.Trim());
        }

        public static bool IsAbsoluteUri(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return true;
            }

            return Uri.TryCreate(value.Trim(), UriKind.Absolute, out _);
        }

        public static bool IsGuid(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return false;
            }

            return Guid.TryParse(value.Trim(), out _);
        }

        public static bool IsNumericCode(string? value, int exactLength)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return false;
            }

            var normalized = NormalizeCompact(value);
            return normalized.Length == exactLength && NumericCodeRegex().IsMatch(normalized);
        }

        public static string NormalizeCompact(string? value)
        {
            return (value ?? string.Empty)
                .Trim()
                .Replace(" ", string.Empty, StringComparison.Ordinal);
        }

        [GeneratedRegex(@"^[0-9+\-\s()]+$")]
        private static partial Regex PhoneRegex();

        [GeneratedRegex(@"^\d+$")]
        private static partial Regex NumericCodeRegex();
    }
}
