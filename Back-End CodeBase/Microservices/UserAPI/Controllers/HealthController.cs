using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UserAPI.Models;
using UserAPI.Services;

namespace UserAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [AllowAnonymous]
    public class HealthController : Controller
    {
        private readonly IHealthService _healthService;

        public HealthController(IHealthService healthService)
        {
            _healthService = healthService;
        }

        [HttpGet]
        public IActionResult Get()
        {
            var msg = new Message<object>();
            msg.StatusCode = 200;
            msg.IsSuccess = true;
            msg.ReturnMessage = "Healthy";
            return Ok(msg);
        }

        [HttpGet]
        [Route("ready")]
        public async Task<IActionResult> Ready(CancellationToken cancellationToken)
        {
            Message<object> msg = await _healthService.GetDatabaseHealth(cancellationToken);
            return StatusCode(msg.StatusCode, msg);
        }
    }
}
