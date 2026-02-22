@echo off
setlocal enabledelayedexpansion
title 端口进程深度分析 (含内存显示)

:: --- 自动提权 ---
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' ( goto UACPrompt ) else ( goto gotAdmin )
:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs" & exit /B
:gotAdmin

:menu
cls
echo ============================================================
echo           Windows 端口进程溯源 (含内存监控)
echo ============================================================
echo.
set /p port=请输入要查询的端口号: 

echo.
set "found_pid="
for /f "tokens=5" %%p in ('netstat -ano ^| findstr :%port% ^| findstr LISTENING') do (set "found_pid=%%p")

if "%found_pid%"=="" (
    echo [提示] 端口 %port% 未被占用。
    pause & goto menu
)

echo [分析结果]
echo ------------------------------------------------------------
:: 增加内存计算逻辑 (WS / 1MB)
powershell -Command "$p = Get-Process -Id %found_pid% -ErrorAction SilentlyContinue; $cp = Get-CimInstance Win32_Process -Filter \"ProcessId = %found_pid%\"; if($p -and $cp){ $mem = [Math]::Round($p.WorkingSet64 / 1MB, 2); $cmd = $cp.CommandLine; $mainClass = $cmd.Split(' ')[-1]; $projectPath = if($cmd -match '-classpath\s+\"(.*?);'){ $matches[1] } else { '未知' }; $jvmArgs = $cmd -replace '-classpath\s+\".*?\"\s+', ' ' -replace ('\s+' + [regex]::Escape($mainClass) + '$'), ''; $jvmArgs = $jvmArgs.Trim(); Write-Host '程序名称 :' $p.ProcessName -ForegroundColor Cyan; Write-Host '进程 ID   :' $p.Id -ForegroundColor Cyan; Write-Host '内存占用 :' \"$mem MB\" -ForegroundColor Magenta; Write-Host '------------------------------------------------------------'; Write-Host '【项目地址】: ' -NoNewline; Write-Host $projectPath -ForegroundColor Green; Write-Host '【启动类】  : ' -NoNewline; Write-Host $mainClass -ForegroundColor Yellow; Write-Host '【JVM参数】 : ' -NoNewline; Write-Host $jvmArgs; } else { Write-Host '无法获取进程完整信息' -ForegroundColor Red }"
echo ------------------------------------------------------------

echo.
echo [1] 终止进程 [2] 重新查询 [3] 退出
set /p opt=请选择操作: 

if "%opt%"=="1" ( 
    taskkill /F /PID %found_pid% /T 
    echo.
    echo 已成功清理进程。 
    pause & goto menu 
)
if "%opt%"=="2" goto menu
exit