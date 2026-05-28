using System.Globalization;

namespace Localization.Validation
{
    internal static class ValidationResourceAccessor
    {
        public static string Get(string resourceName)
        {
            return CurrentProvider.Get(resourceName);
        }

        public static string Format(string resourceName, params object[] args)
        {
            return string.Format(CurrentProvider.Culture, Get(resourceName), args);
        }

        private static ResourceProvider CurrentProvider => new(ResolveLocale());

        private static string? ResolveLocale()
        {
            var culture = CultureInfo.CurrentUICulture;
            if (!string.IsNullOrWhiteSpace(culture.Name))
            {
                return culture.Name;
            }

            return culture.TwoLetterISOLanguageName;
        }
    }
}
