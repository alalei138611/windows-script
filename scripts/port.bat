<# :
@echo off
setlocal enabledelayedexpansion
title Windows Port Process Analyzer (De-duplicated)

:: --- 1. Auto Admin Privilege Elevation ---
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    goto UACPrompt
) else ( goto gotAdmin )
:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs" & exit /B
:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )

:menu
cls
echo ============================================================
echo           Windows Port Process Analyzer (Stable)
echo ============================================================
echo.
set /p port=Enter Port Number: 

if "%port%"=="" goto menu

echo.
echo Analyzing Port %port%...
echo ------------------------------------------------------------

:: --- 2. Pass Port and Current PID ---
powershell -NoProfile -ExecutionPolicy Bypass -Command "$code = (Get-Content '%~f0') -join \"`n\"; & ([scriptblock]::Create($code)) '%port%' '$PID'"

echo.
echo [1] Kill Process (by PID) [2] Search Again [3] Exit
set /p opt=Select Option (1/2/3): 

if "%opt%"=="1" (
    set /p kpid=Enter PID to Kill: 
    if not "!kpid!"=="" (
        taskkill /F /PID !kpid! /T
        echo Process !kpid! has been terminated.
    )
    pause & goto menu
)
if "%opt%"=="2" goto menu
if "%opt%"=="3" exit
goto menu

:: --- 3. PowerShell Code ---
#>

$port = $args[0]
$myPid = $args[1]
if (!$port) { return }

$found = $false
# Use a HashSet to track PIDs we've already displayed
$displayedPids = New-Object System.Collections.Generic.HashSet[string]

# Capture netstat output
$netstat = netstat -ano | Select-String (":" + $port + "\s+")

foreach ($line in $netstat) {
    $fields = $line.ToString().Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
    if ($fields.Count -lt 5) { continue }
    
    $local = $fields[1]
    $stat = $fields[3]
    $foundPid = $fields[4]
    
    # 1. Precise match for local port binding
    # 2. Ignore the script's own PID
    # 3. Skip if this PID has already been displayed
    if ($local -match (':' + $port + '$') -and $foundPid -ne '0' -and $foundPid -ne $myPid -and -not $displayedPids.Contains($foundPid)) {
        
        $pr = Get-Process -Id $foundPid -ErrorAction SilentlyContinue
        $cim = Get-CimInstance Win32_Process -Filter "ProcessId = $foundPid" -ErrorAction SilentlyContinue
        
        if ($pr) {
            $found = $true
            $null = $displayedPids.Add($foundPid) # Mark this PID as displayed
            
            $mem = [Math]::Round($pr.WorkingSet64/1MB, 2)
            $cmd = if($cim){$cim.CommandLine}else{'Unknown'}
            
            # Default values
            $path = 'Unknown'; $mc = 'Unknown'; $jvm = $cmd
            
            # Logic for Java processes (Spring Boot, etc.)
            if ($cmd -match '-classpath\s+\"(.*?);') { 
                $path = $Matches[1] 
                $mc = $cmd.Split(' ')[-1]
                # Strip the binary path and classpath to make JVM Args readable
                $jvm = $cmd -replace '^".*?java\.exe"\s+', '' -replace '-classpath\s+\".*?\"\s+', '[CP] ' -replace ('\s+' + [System.Text.RegularExpressions.Regex]::Escape($mc) + '$'), ''
            } elseif ($cmd -ne 'Unknown') {
                $parts = $cmd.Split(' ')
                $mc = $parts[0]
            }
            
            Write-Host ("[FOUND] State: $stat | PID: $foundPid | Name: $($pr.ProcessName)") -ForegroundColor Cyan
            Write-Host ("Memory : $mem MB") -ForegroundColor Magenta
            Write-Host '------------------------------------------------------------'
            Write-Host 'Project Path: ' -NoNewline; Write-Host $path -ForegroundColor Green
            Write-Host 'Main Class  : ' -NoNewline; Write-Host $mc -ForegroundColor Yellow
            Write-Host 'JVM Args    : ' -NoNewline; Write-Host $jvm.Trim()
            Write-Host '------------------------------------------------------------'
        }
    }
}

if (-not $found) {
    Write-Host 'No local process found using this port.' -ForegroundColor Gray
}