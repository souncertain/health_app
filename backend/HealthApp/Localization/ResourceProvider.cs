using System.Globalization;
using System.Resources;

namespace Localization
{
    public sealed class ResourceProvider
    {
        private const string DefaultLocale = "ru";
        private const string ResourceBaseName = "Localization.Properties.Resources";
        private static readonly ResourceManager ResourceManager = new(ResourceBaseName, typeof(ResourceProvider).Assembly);

        public ResourceProvider(string? locale = null)
        {
            Culture = ResolveCulture(locale);
        }

        public CultureInfo Culture { get; }

        public string Get(string resourceName)
        {
            return ResourceManager.GetString(resourceName, Culture)
                ?? ResourceManager.GetString(resourceName, CultureInfo.GetCultureInfo(DefaultLocale))
                ?? resourceName;
        }

        private static CultureInfo ResolveCulture(string? locale)
        {
            if (!string.IsNullOrWhiteSpace(locale))
            {
                try
                {
                    return CultureInfo.GetCultureInfo(locale);
                }
                catch (CultureNotFoundException)
                {
                }
            }

            return CultureInfo.GetCultureInfo(DefaultLocale);
        }
    }
}
