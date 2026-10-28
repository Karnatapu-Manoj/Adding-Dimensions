using Microsoft.AspNetCore.Diagnostics;
using TeachersAPI.Models;
using TeachersAPI.Utility;

namespace TeachersAPI
{
    public class AppExceptionHandler : IExceptionHandler
    {
        private readonly ILogger<AppExceptionHandler> _logger;

        public AppExceptionHandler(ILogger<AppExceptionHandler> logger)
        {
            _logger = logger;
        }

        public async ValueTask<bool> TryHandleAsync(HttpContext httpContext, Exception exception,
            CancellationToken cancellationToken)
        {
            var msg = new Message<object>();
            ResponseHelper.SetError(msg, exception, _logger, "Unhandled request");
            httpContext.Response.StatusCode = msg.StatusCode;
            await httpContext.Response.WriteAsJsonAsync(msg, cancellationToken);
            return true;
        }
    }
}
