using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KiteMarketDataService.Worker.Migrations
{
    /// <inheritdoc />
    public partial class AddLoadDateToInstruments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Skip dropping tables that don't exist
            // migrationBuilder.DropTable(name: "CircuitLimitChangeHistory");
            // migrationBuilder.DropTable(name: "DailyMarketSnapshots");
            // migrationBuilder.DropTable(name: "OptionsGreeks");

            migrationBuilder.DropPrimaryKey(
                name: "PK_MarketQuotes",
                table: "MarketQuotes");

            migrationBuilder.DropIndex(
                name: "IX_MarketQuotes_TradingDate",
                table: "MarketQuotes");

            migrationBuilder.DropIndex(
                name: "IX_MarketQuotes_TradingDate_TradingSymbol_QuoteTimestamp",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "Id",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "AveragePrice",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "BuyOrders1",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "BuyOrders2",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "BuyOrders3",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "BuyOrders4",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "BuyOrders5",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "BuyPrice1",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "BuyPrice2",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "BuyPrice3",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "BuyPrice4",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "BuyPrice5",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "BuyQuantity",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "BuyQuantity1",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "BuyQuantity2",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "BuyQuantity3",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "BuyQuantity4",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "BuyQuantity5",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "Exchange",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "LastQuantity",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "NetChange",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "OiDayHigh",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "OiDayLow",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "OpenInterest",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "SellOrders1",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "SellOrders2",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "SellOrders3",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "SellOrders4",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "SellOrders5",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "SellPrice1",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "SellPrice2",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "SellPrice3",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "SellPrice4",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "SellPrice5",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "SellQuantity",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "SellQuantity1",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "SellQuantity2",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "SellQuantity3",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "SellQuantity4",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "SellQuantity5",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "SettlementPrice",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "TradeTime",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "TradingDate",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "Volume",
                table: "MarketQuotes");

            migrationBuilder.RenameColumn(
                name: "QuoteTimestamp",
                table: "MarketQuotes",
                newName: "RecordDateTime");

            migrationBuilder.RenameIndex(
                name: "IX_MarketQuotes_QuoteTimestamp",
                table: "MarketQuotes",
                newName: "IX_MarketQuotes_RecordDateTime");

            migrationBuilder.AlterColumn<DateTime>(
                name: "LastTradeTime",
                table: "MarketQuotes",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified),
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "InsertionSequence",
                table: "MarketQuotes",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "ExpiryDate",
                table: "MarketQuotes",
                type: "date",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<DateTime>(
                name: "BusinessDate",
                table: "MarketQuotes",
                type: "date",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified),
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldNullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "LoadDate",
                table: "Instruments",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddPrimaryKey(
                name: "PK_MarketQuotes",
                table: "MarketQuotes",
                columns: new[] { "BusinessDate", "TradingSymbol", "InsertionSequence" });

            migrationBuilder.CreateTable(
                name: "ExcelExportData",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    BusinessDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiryDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Strike = table.Column<int>(type: "int", precision: 10, scale: 2, nullable: false),
                    OptionType = table.Column<string>(type: "nvarchar(2)", maxLength: 2, nullable: false),
                    OpenPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    HighPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LowPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    ClosePrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LastPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LCUCTimeData = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    AdditionalData = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ExportDateTime = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExportType = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    FilePath = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ExcelExportData", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_MarketQuotes_BusinessDate",
                table: "MarketQuotes",
                column: "BusinessDate");

            migrationBuilder.CreateIndex(
                name: "IX_MarketQuotes_BusinessDate_ExpiryDate",
                table: "MarketQuotes",
                columns: new[] { "BusinessDate", "ExpiryDate" });

            migrationBuilder.CreateIndex(
                name: "IX_MarketQuotes_BusinessDate_TradingSymbol",
                table: "MarketQuotes",
                columns: new[] { "BusinessDate", "TradingSymbol" });

            migrationBuilder.CreateIndex(
                name: "IX_MarketQuotes_InsertionSequence",
                table: "MarketQuotes",
                column: "InsertionSequence");

            migrationBuilder.CreateIndex(
                name: "IX_MarketQuotes_TradingSymbol_BusinessDate_RecordDateTime",
                table: "MarketQuotes",
                columns: new[] { "TradingSymbol", "BusinessDate", "RecordDateTime" });

            migrationBuilder.CreateIndex(
                name: "IX_MarketQuotes_TradingSymbol_ExpiryDate_Strike_OptionType",
                table: "MarketQuotes",
                columns: new[] { "TradingSymbol", "ExpiryDate", "Strike", "OptionType" });

            migrationBuilder.CreateIndex(
                name: "IX_ExcelExportData_BusinessDate",
                table: "ExcelExportData",
                column: "BusinessDate");

            migrationBuilder.CreateIndex(
                name: "IX_ExcelExportData_BusinessDate_ExpiryDate",
                table: "ExcelExportData",
                columns: new[] { "BusinessDate", "ExpiryDate" });

            migrationBuilder.CreateIndex(
                name: "IX_ExcelExportData_BusinessDate_ExpiryDate_Strike_OptionType",
                table: "ExcelExportData",
                columns: new[] { "BusinessDate", "ExpiryDate", "Strike", "OptionType" });

            migrationBuilder.CreateIndex(
                name: "IX_ExcelExportData_ExpiryDate",
                table: "ExcelExportData",
                column: "ExpiryDate");

            migrationBuilder.CreateIndex(
                name: "IX_ExcelExportData_ExportDateTime",
                table: "ExcelExportData",
                column: "ExportDateTime");

            migrationBuilder.CreateIndex(
                name: "IX_ExcelExportData_ExportType",
                table: "ExcelExportData",
                column: "ExportType");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ExcelExportData");

            migrationBuilder.DropPrimaryKey(
                name: "PK_MarketQuotes",
                table: "MarketQuotes");

            migrationBuilder.DropIndex(
                name: "IX_MarketQuotes_BusinessDate",
                table: "MarketQuotes");

            migrationBuilder.DropIndex(
                name: "IX_MarketQuotes_BusinessDate_ExpiryDate",
                table: "MarketQuotes");

            migrationBuilder.DropIndex(
                name: "IX_MarketQuotes_BusinessDate_TradingSymbol",
                table: "MarketQuotes");

            migrationBuilder.DropIndex(
                name: "IX_MarketQuotes_InsertionSequence",
                table: "MarketQuotes");

            migrationBuilder.DropIndex(
                name: "IX_MarketQuotes_TradingSymbol_BusinessDate_RecordDateTime",
                table: "MarketQuotes");

            migrationBuilder.DropIndex(
                name: "IX_MarketQuotes_TradingSymbol_ExpiryDate_Strike_OptionType",
                table: "MarketQuotes");

            migrationBuilder.DropColumn(
                name: "LoadDate",
                table: "Instruments");

            migrationBuilder.RenameColumn(
                name: "RecordDateTime",
                table: "MarketQuotes",
                newName: "QuoteTimestamp");

            migrationBuilder.RenameIndex(
                name: "IX_MarketQuotes_RecordDateTime",
                table: "MarketQuotes",
                newName: "IX_MarketQuotes_QuoteTimestamp");

            migrationBuilder.AlterColumn<DateTime>(
                name: "LastTradeTime",
                table: "MarketQuotes",
                type: "datetime2",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "datetime2");

            migrationBuilder.AlterColumn<DateTime>(
                name: "ExpiryDate",
                table: "MarketQuotes",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "date");

            migrationBuilder.AlterColumn<int>(
                name: "InsertionSequence",
                table: "MarketQuotes",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<DateTime>(
                name: "BusinessDate",
                table: "MarketQuotes",
                type: "datetime2",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "date");

            migrationBuilder.AddColumn<long>(
                name: "Id",
                table: "MarketQuotes",
                type: "bigint",
                nullable: false,
                defaultValue: 0L)
                .Annotation("SqlServer:Identity", "1, 1");

            migrationBuilder.AddColumn<decimal>(
                name: "AveragePrice",
                table: "MarketQuotes",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<int>(
                name: "BuyOrders1",
                table: "MarketQuotes",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "BuyOrders2",
                table: "MarketQuotes",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "BuyOrders3",
                table: "MarketQuotes",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "BuyOrders4",
                table: "MarketQuotes",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "BuyOrders5",
                table: "MarketQuotes",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "BuyPrice1",
                table: "MarketQuotes",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "BuyPrice2",
                table: "MarketQuotes",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "BuyPrice3",
                table: "MarketQuotes",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "BuyPrice4",
                table: "MarketQuotes",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "BuyPrice5",
                table: "MarketQuotes",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "BuyQuantity",
                table: "MarketQuotes",
                type: "bigint",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<long>(
                name: "BuyQuantity1",
                table: "MarketQuotes",
                type: "bigint",
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "BuyQuantity2",
                table: "MarketQuotes",
                type: "bigint",
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "BuyQuantity3",
                table: "MarketQuotes",
                type: "bigint",
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "BuyQuantity4",
                table: "MarketQuotes",
                type: "bigint",
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "BuyQuantity5",
                table: "MarketQuotes",
                type: "bigint",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "MarketQuotes",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<string>(
                name: "Exchange",
                table: "MarketQuotes",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<long>(
                name: "LastQuantity",
                table: "MarketQuotes",
                type: "bigint",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<decimal>(
                name: "NetChange",
                table: "MarketQuotes",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "OiDayHigh",
                table: "MarketQuotes",
                type: "decimal(15,2)",
                precision: 15,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "OiDayLow",
                table: "MarketQuotes",
                type: "decimal(15,2)",
                precision: 15,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "OpenInterest",
                table: "MarketQuotes",
                type: "decimal(15,2)",
                precision: 15,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<int>(
                name: "SellOrders1",
                table: "MarketQuotes",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SellOrders2",
                table: "MarketQuotes",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SellOrders3",
                table: "MarketQuotes",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SellOrders4",
                table: "MarketQuotes",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SellOrders5",
                table: "MarketQuotes",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "SellPrice1",
                table: "MarketQuotes",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "SellPrice2",
                table: "MarketQuotes",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "SellPrice3",
                table: "MarketQuotes",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "SellPrice4",
                table: "MarketQuotes",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "SellPrice5",
                table: "MarketQuotes",
                type: "decimal(10,2)",
                precision: 10,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "SellQuantity",
                table: "MarketQuotes",
                type: "bigint",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<long>(
                name: "SellQuantity1",
                table: "MarketQuotes",
                type: "bigint",
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "SellQuantity2",
                table: "MarketQuotes",
                type: "bigint",
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "SellQuantity3",
                table: "MarketQuotes",
                type: "bigint",
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "SellQuantity4",
                table: "MarketQuotes",
                type: "bigint",
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "SellQuantity5",
                table: "MarketQuotes",
                type: "bigint",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "SettlementPrice",
                table: "MarketQuotes",
                type: "decimal(18,2)",
                nullable: true);

            migrationBuilder.AddColumn<TimeSpan>(
                name: "TradeTime",
                table: "MarketQuotes",
                type: "time",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "TradingDate",
                table: "MarketQuotes",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "Volume",
                table: "MarketQuotes",
                type: "bigint",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddPrimaryKey(
                name: "PK_MarketQuotes",
                table: "MarketQuotes",
                column: "Id");

            migrationBuilder.CreateTable(
                name: "CircuitLimitChangeHistory",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ChangeTimestamp = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Close = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    ExpiryDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    High = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    IndexName = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    InstrumentToken = table.Column<long>(type: "bigint", nullable: false),
                    LastTradedPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    Low = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LowerCircuit = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    MarketHourFlag = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Open = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    OptionType = table.Column<string>(type: "nvarchar(2)", maxLength: 2, nullable: false),
                    SpotClose = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    SpotHigh = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    SpotLastPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    SpotLow = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    SpotOpen = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    Strike = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    TradedTime = table.Column<TimeSpan>(type: "time", nullable: false),
                    TradingDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    TradingSymbol = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    UpperCircuit = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CircuitLimitChangeHistory", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "DailyMarketSnapshots",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ClosePrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Exchange = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    ExpiryDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    HighPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    InstrumentToken = table.Column<long>(type: "bigint", nullable: false),
                    LastPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LowPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LowerCircuitLimit = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    NetChange = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    OpenInterest = table.Column<decimal>(type: "decimal(15,2)", precision: 15, scale: 2, nullable: false),
                    OpenPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    OptionType = table.Column<string>(type: "nvarchar(2)", maxLength: 2, nullable: false),
                    SnapshotTime = table.Column<DateTime>(type: "datetime2", nullable: false),
                    SnapshotType = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Strike = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    TradingDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    TradingSymbol = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    UpperCircuitLimit = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    Volume = table.Column<long>(type: "bigint", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DailyMarketSnapshots", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "OptionsGreeks",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    BreakEvenPoint = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    BusinessDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CalculationTime = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ConfidenceScore = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Delta = table.Column<decimal>(type: "decimal(10,6)", precision: 10, scale: 6, nullable: false),
                    DividendYield = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    ExpiryDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Gamma = table.Column<decimal>(type: "decimal(10,8)", precision: 10, scale: 8, nullable: false),
                    HistoricalVolatility = table.Column<decimal>(type: "decimal(8,2)", precision: 8, scale: 2, nullable: false),
                    ImpliedVolatility = table.Column<decimal>(type: "decimal(8,2)", precision: 8, scale: 2, nullable: false),
                    IndexName = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    InstrumentToken = table.Column<long>(type: "bigint", nullable: false),
                    IntrinsicValue = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    LastPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    LowerCircuitLimit = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    MarketSentiment = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    MaximumGain = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    MaximumLoss = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    Moneyness = table.Column<decimal>(type: "decimal(10,4)", precision: 10, scale: 4, nullable: false),
                    OpenInterest = table.Column<decimal>(type: "decimal(15,2)", precision: 15, scale: 2, nullable: false),
                    OptionType = table.Column<string>(type: "nvarchar(2)", maxLength: 2, nullable: false),
                    PredictedHigh = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    PredictedLow = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    PriceDeviation = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    PriceDeviationPercent = table.Column<decimal>(type: "decimal(8,2)", precision: 8, scale: 2, nullable: false),
                    PutCallRatio = table.Column<decimal>(type: "decimal(10,4)", precision: 10, scale: 4, nullable: false),
                    QuoteTimestamp = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Rho = table.Column<decimal>(type: "decimal(10,6)", precision: 10, scale: 6, nullable: false),
                    RiskFreeRate = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    SpotPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    Strike = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    StrikeType = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    TheoreticalPrice = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    Theta = table.Column<decimal>(type: "decimal(10,6)", precision: 10, scale: 6, nullable: false),
                    TimeToExpiry = table.Column<decimal>(type: "decimal(10,6)", precision: 10, scale: 6, nullable: false),
                    TimeValue = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    TradingSymbol = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpperCircuitLimit = table.Column<decimal>(type: "decimal(10,2)", precision: 10, scale: 2, nullable: false),
                    Vega = table.Column<decimal>(type: "decimal(10,6)", precision: 10, scale: 6, nullable: false),
                    VolatilityRank = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    VolatilitySkew = table.Column<decimal>(type: "decimal(8,2)", precision: 8, scale: 2, nullable: false),
                    Volume = table.Column<long>(type: "bigint", nullable: false),
                    VolumeRatio = table.Column<decimal>(type: "decimal(10,4)", precision: 10, scale: 4, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OptionsGreeks", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_MarketQuotes_TradingDate",
                table: "MarketQuotes",
                column: "TradingDate");

            migrationBuilder.CreateIndex(
                name: "IX_MarketQuotes_TradingDate_TradingSymbol_QuoteTimestamp",
                table: "MarketQuotes",
                columns: new[] { "TradingDate", "TradingSymbol", "QuoteTimestamp" });

            migrationBuilder.CreateIndex(
                name: "IX_CircuitLimitChangeHistory_ChangeTimestamp",
                table: "CircuitLimitChangeHistory",
                column: "ChangeTimestamp");

            migrationBuilder.CreateIndex(
                name: "IX_CircuitLimitChangeHistory_ExpiryDate",
                table: "CircuitLimitChangeHistory",
                column: "ExpiryDate");

            migrationBuilder.CreateIndex(
                name: "IX_CircuitLimitChangeHistory_IndexName",
                table: "CircuitLimitChangeHistory",
                column: "IndexName");

            migrationBuilder.CreateIndex(
                name: "IX_CircuitLimitChangeHistory_InstrumentToken",
                table: "CircuitLimitChangeHistory",
                column: "InstrumentToken");

            migrationBuilder.CreateIndex(
                name: "IX_CircuitLimitChangeHistory_Strike",
                table: "CircuitLimitChangeHistory",
                column: "Strike");

            migrationBuilder.CreateIndex(
                name: "IX_CircuitLimitChangeHistory_TradingDate",
                table: "CircuitLimitChangeHistory",
                column: "TradingDate");

            migrationBuilder.CreateIndex(
                name: "IX_CircuitLimitChangeHistory_TradingDate_IndexName_Strike_OptionType_ExpiryDate",
                table: "CircuitLimitChangeHistory",
                columns: new[] { "TradingDate", "IndexName", "Strike", "OptionType", "ExpiryDate" });

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
                name: "IX_OptionsGreeks_BusinessDate",
                table: "OptionsGreeks",
                column: "BusinessDate");

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_BusinessDate_IndexName",
                table: "OptionsGreeks",
                columns: new[] { "BusinessDate", "IndexName" });

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_CalculationTime",
                table: "OptionsGreeks",
                column: "CalculationTime");

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_ExpiryDate",
                table: "OptionsGreeks",
                column: "ExpiryDate");

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_IndexName",
                table: "OptionsGreeks",
                column: "IndexName");

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_IndexName_ExpiryDate_Strike_OptionType",
                table: "OptionsGreeks",
                columns: new[] { "IndexName", "ExpiryDate", "Strike", "OptionType" });

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_InstrumentToken",
                table: "OptionsGreeks",
                column: "InstrumentToken");

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_OptionType",
                table: "OptionsGreeks",
                column: "OptionType");

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_QuoteTimestamp",
                table: "OptionsGreeks",
                column: "QuoteTimestamp");

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_QuoteTimestamp_InstrumentToken",
                table: "OptionsGreeks",
                columns: new[] { "QuoteTimestamp", "InstrumentToken" });

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_Strike",
                table: "OptionsGreeks",
                column: "Strike");

            migrationBuilder.CreateIndex(
                name: "IX_OptionsGreeks_StrikeType",
                table: "OptionsGreeks",
                column: "StrikeType");
        }
    }
}
