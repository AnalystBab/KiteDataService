using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System.ServiceProcess;
using System.Diagnostics;

namespace KiteMarketDataService.Worker.WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ServiceControlController : ControllerBase
    {
        private readonly ILogger<ServiceControlController> _logger;
        private const string SERVICE_NAME = "KiteMarketDataService";

        public ServiceControlController(ILogger<ServiceControlController> logger)
        {
            _logger = logger;
        }

        /// <summary>
        /// Get service status
        /// </summary>
        [HttpGet("status")]
        public IActionResult GetServiceStatus()
        {
            try
            {
                using var service = new ServiceController(SERVICE_NAME);
                var status = service.Status;
                
                return Ok(new
                {
                    ServiceName = SERVICE_NAME,
                    Status = status.ToString(),
                    IsRunning = status == ServiceControllerStatus.Running,
                    CanStart = status == ServiceControllerStatus.Stopped,
                    CanStop = status == ServiceControllerStatus.Running,
                    LastUpdated = DateTime.Now
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking service status");
                return StatusCode(500, new { Message = "Failed to check service status", Error = ex.Message });
            }
        }

        /// <summary>
        /// Start the service
        /// </summary>
        [HttpPost("start")]
        public IActionResult StartService()
        {
            try
            {
                using var service = new ServiceController(SERVICE_NAME);
                
                if (service.Status == ServiceControllerStatus.Running)
                {
                    return Ok(new { Message = "Service is already running", Status = "Running" });
                }

                if (service.Status == ServiceControllerStatus.Stopped)
                {
                    service.Start();
                    service.WaitForStatus(ServiceControllerStatus.Running, TimeSpan.FromSeconds(30));
                    
                    _logger.LogInformation("Service started successfully via web interface");
                    return Ok(new { Message = "Service started successfully", Status = "Running" });
                }

                return BadRequest(new { Message = $"Cannot start service. Current status: {service.Status}" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to start service");
                return StatusCode(500, new { Message = "Failed to start service", Error = ex.Message });
            }
        }

        /// <summary>
        /// Stop the service
        /// </summary>
        [HttpPost("stop")]
        public IActionResult StopService()
        {
            try
            {
                using var service = new ServiceController(SERVICE_NAME);
                
                if (service.Status == ServiceControllerStatus.Stopped)
                {
                    return Ok(new { Message = "Service is already stopped", Status = "Stopped" });
                }

                if (service.Status == ServiceControllerStatus.Running)
                {
                    service.Stop();
                    service.WaitForStatus(ServiceControllerStatus.Stopped, TimeSpan.FromSeconds(30));
                    
                    _logger.LogInformation("Service stopped successfully via web interface");
                    return Ok(new { Message = "Service stopped successfully", Status = "Stopped" });
                }

                return BadRequest(new { Message = $"Cannot stop service. Current status: {service.Status}" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to stop service");
                return StatusCode(500, new { Message = "Failed to stop service", Error = ex.Message });
            }
        }

        /// <summary>
        /// Restart the service
        /// </summary>
        [HttpPost("restart")]
        public IActionResult RestartService()
        {
            try
            {
                using var service = new ServiceController(SERVICE_NAME);
                
                if (service.Status == ServiceControllerStatus.Running)
                {
                    service.Stop();
                    service.WaitForStatus(ServiceControllerStatus.Stopped, TimeSpan.FromSeconds(30));
                }

                service.Start();
                service.WaitForStatus(ServiceControllerStatus.Running, TimeSpan.FromSeconds(30));
                
                _logger.LogInformation("Service restarted successfully via web interface");
                return Ok(new { Message = "Service restarted successfully", Status = "Running" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to restart service");
                return StatusCode(500, new { Message = "Failed to restart service", Error = ex.Message });
            }
        }

        /// <summary>
        /// Install the service (requires admin privileges)
        /// </summary>
        [HttpPost("install")]
        public IActionResult InstallService()
        {
            try
            {
                var processInfo = new ProcessStartInfo
                {
                    FileName = "sc.exe",
                    Arguments = $"create \"{SERVICE_NAME}\" binPath= \"{Environment.ProcessPath}\" start= auto",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                };

                using var process = Process.Start(processInfo);
                process.WaitForExit();

                if (process.ExitCode == 0)
                {
                    _logger.LogInformation("Service installed successfully");
                    return Ok(new { Message = "Service installed successfully" });
                }
                else
                {
                    var error = process.StandardError.ReadToEnd();
                    _logger.LogError($"Failed to install service: {error}");
                    return StatusCode(500, new { Message = "Failed to install service", Error = error });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to install service");
                return StatusCode(500, new { Message = "Failed to install service", Error = ex.Message });
            }
        }

        /// <summary>
        /// Uninstall the service (requires admin privileges)
        /// </summary>
        [HttpPost("uninstall")]
        public IActionResult UninstallService()
        {
            try
            {
                var processInfo = new ProcessStartInfo
                {
                    FileName = "sc.exe",
                    Arguments = $"delete \"{SERVICE_NAME}\"",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                };

                using var process = Process.Start(processInfo);
                process.WaitForExit();

                if (process.ExitCode == 0)
                {
                    _logger.LogInformation("Service uninstalled successfully");
                    return Ok(new { Message = "Service uninstalled successfully" });
                }
                else
                {
                    var error = process.StandardError.ReadToEnd();
                    _logger.LogError($"Failed to uninstall service: {error}");
                    return StatusCode(500, new { Message = "Failed to uninstall service", Error = error });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to uninstall service");
                return StatusCode(500, new { Message = "Failed to uninstall service", Error = ex.Message });
            }
        }
    }
}

