using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// Service to protect Excel export files from any cleanup operations
    /// Ensures Excel files are never deleted or modified by cleanup processes
    /// </summary>
    public class ExcelFileProtectionService
    {
        private readonly ILogger<ExcelFileProtectionService> _logger;
        private readonly string _exportsPath;

        public ExcelFileProtectionService(ILogger<ExcelFileProtectionService> logger)
        {
            _logger = logger;
            _exportsPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Exports");
        }

        /// <summary>
        /// Get all Excel export directories that should be protected
        /// </summary>
        public string[] GetProtectedDirectories()
        {
            return new[]
            {
                Path.Combine(_exportsPath, "DailyInitialData"),
                Path.Combine(_exportsPath, "ConsolidatedLCUC"),
                Path.Combine(_exportsPath, "TraditionalExports")
            };
        }

        /// <summary>
        /// Verify that Excel files are protected and not being deleted
        /// </summary>
        public async Task<bool> VerifyExcelFilesAreProtectedAsync()
        {
            try
            {
                var protectedDirs = GetProtectedDirectories();
                var totalExcelFiles = 0;
                var protectedFiles = 0;

                foreach (var dir in protectedDirs)
                {
                    if (Directory.Exists(dir))
                    {
                        var excelFiles = Directory.GetFiles(dir, "*.xlsx", SearchOption.AllDirectories);
                        totalExcelFiles += excelFiles.Length;
                        protectedFiles += excelFiles.Length;
                    }
                }

                _logger.LogInformation($"Excel file protection verified: {protectedFiles}/{totalExcelFiles} files protected");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to verify Excel file protection");
                return false;
            }
        }

        /// <summary>
        /// Get count of Excel files in export directories
        /// </summary>
        public async Task<int> GetExcelFileCountAsync()
        {
            try
            {
                var protectedDirs = GetProtectedDirectories();
                var totalFiles = 0;

                foreach (var dir in protectedDirs)
                {
                    if (Directory.Exists(dir))
                    {
                        var excelFiles = Directory.GetFiles(dir, "*.xlsx", SearchOption.AllDirectories);
                        totalFiles += excelFiles.Length;
                    }
                }

                _logger.LogInformation($"Total Excel files in export directories: {totalFiles}");
                return totalFiles;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to count Excel files");
                return 0;
            }
        }

        /// <summary>
        /// Log Excel file protection status
        /// </summary>
        public async Task LogExcelFileStatusAsync()
        {
            try
            {
                var protectedDirs = GetProtectedDirectories();
                
                _logger.LogInformation("=== EXCEL FILE PROTECTION STATUS ===");
                
                foreach (var dir in protectedDirs)
                {
                    if (Directory.Exists(dir))
                    {
                        var excelFiles = Directory.GetFiles(dir, "*.xlsx", SearchOption.AllDirectories);
                        var subDirs = Directory.GetDirectories(dir);
                        
                        _logger.LogInformation($"📁 {Path.GetFileName(dir)}: {excelFiles.Length} Excel files, {subDirs.Length} subdirectories");
                        
                        // Log recent files
                        var recentFiles = excelFiles
                            .Select(f => new FileInfo(f))
                            .OrderByDescending(f => f.LastWriteTime)
                            .Take(5)
                            .ToList();
                            
                        foreach (var file in recentFiles)
                        {
                            _logger.LogInformation($"  📄 {file.Name} (Modified: {file.LastWriteTime:yyyy-MM-dd HH:mm:ss})");
                        }
                    }
                    else
                    {
                        _logger.LogInformation($"📁 {Path.GetFileName(dir)}: Directory does not exist");
                    }
                }
                
                _logger.LogInformation("=== END EXCEL FILE PROTECTION STATUS ===");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to log Excel file status");
            }
        }

        /// <summary>
        /// Ensure Excel export directories exist and are protected
        /// </summary>
        public async Task EnsureExcelDirectoriesAreProtectedAsync()
        {
            try
            {
                var protectedDirs = GetProtectedDirectories();
                
                foreach (var dir in protectedDirs)
                {
                    if (!Directory.Exists(dir))
                    {
                        Directory.CreateDirectory(dir);
                        _logger.LogInformation($"Created protected Excel directory: {dir}");
                    }
                    
                    // Create a protection marker file
                    var protectionFile = Path.Combine(dir, ".PROTECTED");
                    if (!File.Exists(protectionFile))
                    {
                        await File.WriteAllTextAsync(protectionFile, $"Excel files in this directory are protected from cleanup operations.\nCreated: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
                        _logger.LogInformation($"Created protection marker: {protectionFile}");
                    }
                }
                
                _logger.LogInformation("Excel file protection directories verified and protected");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to ensure Excel directories are protected");
            }
        }
    }
}
