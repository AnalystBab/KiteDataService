using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KiteMarketDataService.Worker.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "CircuitLimitChanges",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TradingDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ChangeTime = table.Column<DateTime>(type: "datetime2", nullable: false),
                    InstrumentToken = table.Column<long>(type: "bigint", nullable: false),
                    TradingSymbol = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Strike = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    OptionType = table.Column<string>(type: "nvarchar(2)", maxLength: 2, nullable: false),
                    Exchange = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    ExpiryDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ChangeType = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    PreviousLC = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    PreviousUC = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    PreviousOpenPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    PreviousHighPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    PreviousLowPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    PreviousClosePrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    PreviousLastPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    NewLC = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    NewUC = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    NewOpenPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    NewHighPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    NewLowPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    NewClosePrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    NewLastPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    IndexOpenPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    IndexHighPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    IndexLowPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    IndexClosePrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    IndexLastPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CircuitLimitChanges", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "CircuitLimits",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TradingDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    InstrumentToken = table.Column<long>(type: "bigint", nullable: false),
                    TradingSymbol = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Strike = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    OptionType = table.Column<string>(type: "nvarchar(2)", maxLength: 2, nullable: false),
                    LowerCircuitLimit = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    UpperCircuitLimit = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    Source = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    LastUpdated = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CircuitLimits", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "DailyMarketSnapshots",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TradingDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    SnapshotTime = table.Column<DateTime>(type: "datetime2", nullable: false),
                    InstrumentToken = table.Column<long>(type: "bigint", nullable: false),
                    TradingSymbol = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Strike = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    OptionType = table.Column<string>(type: "nvarchar(2)", maxLength: 2, nullable: false),
                    Exchange = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    ExpiryDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    OpenPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    HighPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LowPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    ClosePrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LastPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LowerCircuitLimit = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    UpperCircuitLimit = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    Volume = table.Column<long>(type: "bigint", nullable: false),
                    OpenInterest = table.Column<decimal>(type: "decimal(15,2)", precision: 15, scale: 2, nullable: false),
                    NetChange = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    SnapshotType = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DailyMarketSnapshots", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Instruments",
                columns: table => new
                {
                    InstrumentToken = table.Column<long>(type: "bigint", nullable: false),
                    ExchangeToken = table.Column<long>(type: "bigint", nullable: false),
                    TradingSymbol = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    LastPrice = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Expiry = table.Column<DateTime>(type: "datetime2", nullable: true),
                    Strike = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    TickSize = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    LotSize = table.Column<int>(type: "int", nullable: false),
                    InstrumentType = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    Segment = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Exchange = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Instruments", x => x.InstrumentToken);
                });

            migrationBuilder.CreateTable(
                name: "MarketQuotes",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TradingDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    TradeTime = table.Column<TimeSpan>(type: "time", nullable: false),
                    QuoteTimestamp = table.Column<DateTime>(type: "datetime2", nullable: false),
                    InstrumentToken = table.Column<long>(type: "bigint", nullable: false),
                    TradingSymbol = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Exchange = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Strike = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    OptionType = table.Column<string>(type: "nvarchar(2)", maxLength: 2, nullable: false),
                    ExpiryDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    OpenPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    HighPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LowPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    ClosePrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LastPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LowerCircuitLimit = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    UpperCircuitLimit = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    Volume = table.Column<long>(type: "bigint", nullable: false),
                    LastQuantity = table.Column<long>(type: "bigint", nullable: false),
                    BuyQuantity = table.Column<long>(type: "bigint", nullable: false),
                    SellQuantity = table.Column<long>(type: "bigint", nullable: false),
                    AveragePrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    OpenInterest = table.Column<decimal>(type: "decimal(15,2)", precision: 15, scale: 2, nullable: false),
                    OiDayHigh = table.Column<decimal>(type: "decimal(15,2)", precision: 15, scale: 2, nullable: false),
                    OiDayLow = table.Column<decimal>(type: "decimal(15,2)", precision: 15, scale: 2, nullable: false),
                    NetChange = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    BuyPrice1 = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    BuyQuantity1 = table.Column<long>(type: "bigint", nullable: true),
                    BuyOrders1 = table.Column<int>(type: "int", nullable: true),
                    BuyPrice2 = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    BuyQuantity2 = table.Column<long>(type: "bigint", nullable: true),
                    BuyOrders2 = table.Column<int>(type: "int", nullable: true),
                    BuyPrice3 = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    BuyQuantity3 = table.Column<long>(type: "bigint", nullable: true),
                    BuyOrders3 = table.Column<int>(type: "int", nullable: true),
                    BuyPrice4 = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    BuyQuantity4 = table.Column<long>(type: "bigint", nullable: true),
                    BuyOrders4 = table.Column<int>(type: "int", nullable: true),
                    BuyPrice5 = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    BuyQuantity5 = table.Column<long>(type: "bigint", nullable: true),
                    BuyOrders5 = table.Column<int>(type: "int", nullable: true),
                    SellPrice1 = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    SellQuantity1 = table.Column<long>(type: "bigint", nullable: true),
                    SellOrders1 = table.Column<int>(type: "int", nullable: true),
                    SellPrice2 = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    SellQuantity2 = table.Column<long>(type: "bigint", nullable: true),
                    SellOrders2 = table.Column<int>(type: "int", nullable: true),
                    SellPrice3 = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    SellQuantity3 = table.Column<long>(type: "bigint", nullable: true),
                    SellOrders3 = table.Column<int>(type: "int", nullable: true),
                    SellPrice4 = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    SellQuantity4 = table.Column<long>(type: "bigint", nullable: true),
                    SellOrders4 = table.Column<int>(type: "int", nullable: true),
                    SellPrice5 = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: true),
                    SellQuantity5 = table.Column<long>(type: "bigint", nullable: true),
                    SellOrders5 = table.Column<int>(type: "int", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    InstrumentToken1 = table.Column<long>(type: "bigint", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MarketQuotes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MarketQuotes_Instruments_InstrumentToken1",
                        column: x => x.InstrumentToken1,
                        principalTable: "Instruments",
                        principalColumn: "InstrumentToken");
                });

            migrationBuilder.CreateIndex(
                name: "IX_CircuitLimitChanges_ChangeTime",
                table: "CircuitLimitChanges",
                column: "ChangeTime");

            migrationBuilder.CreateIndex(
                name: "IX_CircuitLimitChanges_ChangeType",
                table: "CircuitLimitChanges",
                column: "ChangeType");

            migrationBuilder.CreateIndex(
                name: "IX_CircuitLimitChanges_InstrumentToken",
                table: "CircuitLimitChanges",
                column: "InstrumentToken");

            migrationBuilder.CreateIndex(
                name: "IX_CircuitLimitChanges_TradingDate",
                table: "CircuitLimitChanges",
                column: "TradingDate");

            migrationBuilder.CreateIndex(
                name: "IX_CircuitLimits_InstrumentToken",
                table: "CircuitLimits",
                column: "InstrumentToken");

            migrationBuilder.CreateIndex(
                name: "IX_CircuitLimits_TradingDate",
                table: "CircuitLimits",
                column: "TradingDate");

            migrationBuilder.CreateIndex(
                name: "IX_CircuitLimits_TradingDate_TradingSymbol",
                table: "CircuitLimits",
                columns: new[] { "TradingDate", "TradingSymbol" });

            migrationBuilder.CreateIndex(
                name: "IX_DailyMarketSnapshots_InstrumentToken",
                table: "DailyMarketSnapshots",
                column: "InstrumentToken");

            migrationBuilder.CreateIndex(
                name: "IX_DailyMarketSnapshots_SnapshotTime",
                table: "DailyMarketSnapshots",
                column: "SnapshotTime");

            migrationBuilder.CreateIndex(
                name: "IX_DailyMarketSnapshots_SnapshotType",
                table: "DailyMarketSnapshots",
                column: "SnapshotType");

            migrationBuilder.CreateIndex(
                name: "IX_DailyMarketSnapshots_TradingDate",
                table: "DailyMarketSnapshots",
                column: "TradingDate");

            migrationBuilder.CreateIndex(
                name: "IX_Instruments_Exchange",
                table: "Instruments",
                column: "Exchange");

            migrationBuilder.CreateIndex(
                name: "IX_Instruments_Expiry",
                table: "Instruments",
                column: "Expiry");

            migrationBuilder.CreateIndex(
                name: "IX_Instruments_InstrumentType",
                table: "Instruments",
                column: "InstrumentType");

            migrationBuilder.CreateIndex(
                name: "IX_Instruments_TradingSymbol",
                table: "Instruments",
                column: "TradingSymbol");

            migrationBuilder.CreateIndex(
                name: "IX_MarketQuotes_ExpiryDate",
                table: "MarketQuotes",
                column: "ExpiryDate");

            migrationBuilder.CreateIndex(
                name: "IX_MarketQuotes_InstrumentToken",
                table: "MarketQuotes",
                column: "InstrumentToken");

            migrationBuilder.CreateIndex(
                name: "IX_MarketQuotes_InstrumentToken1",
                table: "MarketQuotes",
                column: "InstrumentToken1");

            migrationBuilder.CreateIndex(
                name: "IX_MarketQuotes_OptionType",
                table: "MarketQuotes",
                column: "OptionType");

            migrationBuilder.CreateIndex(
                name: "IX_MarketQuotes_QuoteTimestamp",
                table: "MarketQuotes",
                column: "QuoteTimestamp");

            migrationBuilder.CreateIndex(
                name: "IX_MarketQuotes_Strike",
                table: "MarketQuotes",
                column: "Strike");

            migrationBuilder.CreateIndex(
                name: "IX_MarketQuotes_TradingDate",
                table: "MarketQuotes",
                column: "TradingDate");

            migrationBuilder.CreateIndex(
                name: "IX_MarketQuotes_TradingDate_TradingSymbol_QuoteTimestamp",
                table: "MarketQuotes",
                columns: new[] { "TradingDate", "TradingSymbol", "QuoteTimestamp" });

            migrationBuilder.CreateIndex(
                name: "IX_MarketQuotes_TradingSymbol",
                table: "MarketQuotes",
                column: "TradingSymbol");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "CircuitLimitChanges");

            migrationBuilder.DropTable(
                name: "CircuitLimits");

            migrationBuilder.DropTable(
                name: "DailyMarketSnapshots");

            migrationBuilder.DropTable(
                name: "MarketQuotes");

            migrationBuilder.DropTable(
                name: "Instruments");
        }
    }
}
