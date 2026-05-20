using System.Net;

namespace Domain.Exceptions
{
    public class AuthException : Exception
    {
        public AuthException(string message, HttpStatusCode statusCode = HttpStatusCode.BadRequest)
            : base(message)
        {
            StatusCode = statusCode;
        }

        public HttpStatusCode StatusCode { get; }
    }
}
