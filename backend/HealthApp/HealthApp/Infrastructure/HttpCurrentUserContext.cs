using Data.Interfaces;
using System.Security.Claims;

namespace HealthApp.Infrastructure
{
    public class HttpCurrentUserContext : ICurrentUserContext
    {
        private const string UserIdHeaderName = "X-User-Id";
        private readonly IHttpContextAccessor _httpContextAccessor;

        public HttpCurrentUserContext(IHttpContextAccessor httpContextAccessor)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        public Guid? UserId
        {
            get
            {
                var httpContext = _httpContextAccessor.HttpContext;
                if (httpContext is null)
                {
                    return null;
                }

                var claimValue = httpContext.User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (Guid.TryParse(claimValue, out var claimUserId))
                {
                    return claimUserId;
                }

                if (httpContext.Request.Headers.TryGetValue(UserIdHeaderName, out var headerValues) &&
                    Guid.TryParse(headerValues.FirstOrDefault(), out var headerUserId))
                {
                    return headerUserId;
                }

                return null;
            }
        }

        public bool HasUserId => UserId.HasValue;
    }
}
