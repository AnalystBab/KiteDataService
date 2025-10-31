using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KiteMarketDataService.Worker.Models
{
    /// <summary>
    /// Stores Kite Connect authentication configuration in database
    /// Replaces appsettings.json for authentication fields
    /// </summary>
    [Table("AuthConfiguration")]
    public class AuthConfiguration
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string ApiKey { get; set; } = string.Empty;

        [Required]
        [MaxLength(200)]
        public string ApiSecret { get; set; } = string.Empty;

        [MaxLength(200)]
        public string? RequestToken { get; set; }

        [MaxLength(200)]
        public string? AccessToken { get; set; }

        [Required]
        public bool IsActive { get; set; } = true;

        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        [Required]
        public DateTime UpdatedAt { get; set; } = DateTime.Now;

        [MaxLength(500)]
        public string? Notes { get; set; }
    }
}
