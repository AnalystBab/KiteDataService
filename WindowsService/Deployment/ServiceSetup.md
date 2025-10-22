# 🚀 Windows Service Setup Guide

This guide shows you how to implement the Windows Service functionality step by step.

## 📋 Prerequisites

- Windows 10/11 or Windows Server
- .NET 9.0 Runtime installed
- Administrator privileges
- Main project built and working

## 🎯 Step-by-Step Implementation

### **Step 1: Copy Files to Main Project**

Copy the following files from `WindowsService/` folder to your main project:

```
WindowsService/Services/WindowsServiceInstaller.cs → Services/WindowsServiceInstaller.cs
WindowsService/Controllers/ServiceControlController.cs → WebApi/Controllers/ServiceControlController.cs
WindowsService/WebInterface/token-management.html → wwwroot/token-management.html
WindowsService/Scripts/InstallService.ps1 → InstallService.ps1
WindowsService/Scripts/ManageService.bat → ManageService.bat
```

### **Step 2: Update Project File**

Add this line to your `KiteMarketDataService.Worker.csproj`:

```xml
<PackageReference Include="Microsoft.Extensions.Hosting.WindowsServices" Version="9.0.1" />
```

### **Step 3: Build the Project**

```bash
dotnet build --configuration Release
```

### **Step 4: Install Windows Service**

1. **Run as Administrator:**
   - Right-click on `ManageService.bat`
   - Select "Run as administrator"

2. **Choose Option 1:**
   - Select "1. Install Windows Service"
   - Wait for installation to complete

### **Step 5: Start the Service**

1. **Option A: Via Web Interface**
   - Open `http://localhost:5000/token-management.html`
   - Click "Start Service" button

2. **Option B: Via Management Script**
   - Run `ManageService.bat` as Administrator
   - Choose "3. Start Service"

### **Step 6: Verify Everything Works**

1. **Check Service Status:**
   - Open `http://localhost:5000/token-management.html`
   - Should show "Service is Running" with green indicator

2. **Test Service Control:**
   - Try "Stop Service" button
   - Try "Start Service" button
   - Try "Restart Service" button

3. **Test Token Management:**
   - Click "Login to Kite Connect"
   - Get request token
   - Update token via web interface

## 🎯 What You Get After Implementation

### **✅ Web-Based Service Control**
- Start/Stop/Restart service via web interface
- Real-time service status monitoring
- No command line required

### **✅ Automatic Startup**
- Service starts automatically when Windows boots
- Runs in background 24/7
- No manual intervention needed

### **✅ Professional Deployment**
- Runs as Windows Service
- Proper logging and error handling
- Service management via Windows Services console

### **✅ Easy Management**
- All control through web interface
- User-friendly interface
- No technical knowledge required

## 🔧 Troubleshooting

### **Service Won't Start**
1. Check if port 5000 is available
2. Run as Administrator
3. Check Windows Event Log for errors

### **Web Interface Not Loading**
1. Ensure service is running
2. Check firewall settings
3. Verify port 5000 is not blocked

### **Permission Errors**
1. Run all scripts as Administrator
2. Check Windows Service permissions
3. Verify .NET runtime is installed

## 📞 Support

If you encounter issues:

1. **Check Windows Event Log** for service errors
2. **Verify all files** are copied correctly
3. **Ensure Administrator privileges** for installation
4. **Check port 5000** is not in use by other applications

## 🎉 Success!

Once implemented, you'll have:

- ✅ **Fully web-based service control**
- ✅ **Automatic Windows startup**
- ✅ **Professional deployment**
- ✅ **24/7 operation**
- ✅ **Easy token management**

Your service will now run like a professional Windows application!






