using Microsoft.AspNetCore.Mvc;
using System.Diagnostics;
using Microsoft.Extensions.Logging;

namespace KiteMarketDataService.Worker.WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BackgroundManagerController : ControllerBase
    {
        private readonly ILogger<BackgroundManagerController> _logger;

        // Root folder where the scripts live
        private static readonly string ProjectRoot = AppDomain.CurrentDomain.BaseDirectory;
        private static readonly string ScriptPath = Path.Combine(ProjectRoot, "BackgroundServiceManager", "Scripts", "01-Start-Stop-Restart-Service.ps1");

        public BackgroundManagerController(ILogger<BackgroundManagerController> logger)
        {
            _logger = logger;
        }

        [HttpPost("start")]
        public IActionResult Start()
        {
            try
            {
                var output = RunPowerShell($"& '{ScriptPath}'");
                return Ok(new { success = true, message = "Service start requested", output });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to start service via script");
                return StatusCode(500, new { success = false, error = ex.Message });
            }
        }

        [HttpPost("stop")]
        public IActionResult Stop()
        {
            try
            {
                var output = RunPowerShell($"& '{ScriptPath}' -Stop");
                return Ok(new { success = true, message = "Service stop requested", output });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to stop service via script");
                return StatusCode(500, new { success = false, error = ex.Message });
            }
        }

        [HttpGet("status")]
        public IActionResult Status()
        {
            try
            {
                var output = RunPowerShell($"& '{ScriptPath}' -Status");
                return Ok(new { success = true, output });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to check service status via script");
                return StatusCode(500, new { success = false, error = ex.Message });
            }
        }

        private static string RunPowerShell(string command)
        {
            var psi = new ProcessStartInfo
            {
                FileName = "powershell",
                Arguments = $"-ExecutionPolicy Bypass -NoProfile -Command \"{command}\"",
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            using var process = Process.Start(psi)!;
            var stdout = process.StandardOutput.ReadToEnd();
            var stderr = process.StandardError.ReadToEnd();
            process.WaitForExit(30000);

            if (process.ExitCode != 0 && !string.IsNullOrWhiteSpace(stderr))
            {
                throw new InvalidOperationException(stderr.Trim());
            }

            return stdout.Trim();
        }
    }
}


