@echo off
setlocal
cls
color 0a
title Oracle Manager by Zero

:: 执行需要管理员权限的命令（有权限返回0，无权限返回5）
>nul 2>&1 "%SYSTEMROOT%\system32\icacls.exe" "%SYSTEMROOT%\system32\config\system"
if "%ERRORLEVEL%" NEQ "0" (
    goto getAdmin
) else (
    goto getStart
)

:: 无权限尝试获取权限
:getAdmin
:: 使用 PowerShell 请求提权（VBScript 在新版 Windows 11 已弃用，可能无脚本引擎）
powershell -NoProfile -Command "Start-Process -FilePath '%~s0' -Verb RunAs"
exit /B

:: 有权限继续执行
:getStart

:: 服务名与 SID 配置，回车使用默认值
:: 在提权之后询问，避免提权重启后重复输入
:: 监听器服务名随版本变化：18c/21c XE 形如 OracleOraDB21Home1TNSListener，
:: 10g/11g XE 为 OracleXETNSListener；序号由安装程序按已有 ORACLE_HOME 决定，按实际填写
set "serviceName=OracleServiceXE"
set "listenerName=OracleOraDB21Home1TNSListener"
set "oracleSid=XE"
set /p "serviceName=Enter Oracle service name [default: %serviceName%]: "
set /p "listenerName=Enter Oracle listener service name [default: %listenerName%]: "
set /p "oracleSid=Enter Oracle SID [default: %oracleSid%]: "

goto checkService

:: 菜单
:menu
cls
echo.
:: 显示主服务与监听器当前状态（sc query 输出 STATE 行的第 4 个字段）
for /f "tokens=4" %%s in ('sc query "%serviceName%" ^| findstr /I "STATE"') do (
    echo.Service status ^(%serviceName%^): %%s
)
for /f "tokens=4" %%s in ('sc query "%listenerName%" ^| findstr /I "STATE"') do (
    echo.Listener status ^(%listenerName%^): %%s
)
echo.
echo.=-=-=-=- Please select the operation you want to perform on Oracle (SID: %oracleSid%) -=-=-=-=-
echo.
echo.1: Startup Oracle
echo.
echo.2: Shutdown Oracle
echo.
echo.3: Reboot Oracle
echo.
echo.4: Exit
echo.
echo.=-=-=-=- Please enter the item number you want to select -=-=-=-
set /p id=
:: 非交互运行（stdin 已关闭）时直接退出，避免菜单死循环
if errorlevel 1 exit /b
if "%id%"=="1" (
    call :startup
    goto quit
) else if "%id%"=="2" (
    call :shutdown
    goto quit
) else if "%id%"=="3" (
    call :reboot
    goto quit
) else if "%id%"=="4" (
    exit /b 0
) else (
    echo Warning: Wrong item number!
    :: 暂停3秒
    ping -n 3 127.0.0.1 > nul
    goto menu
)

:: 启动（先起监听器，再起主服务；两者分别判断，避免其中一个已在运行时 net start 报错）
:: 说明：OracleServiceXxx（Xxx 为 SID）服务启动时即会拉起数据库实例（XE 安装默认为 autostart），
:: Oracle XE 官方文档给出的控制方式就是 Windows 服务（net start/stop），故不调用 oradim：
:: oradim 位于 %ORACLE_HOME%\bin，未加入 PATH 时直接报"不是内部或外部命令"，
:: 且 -starttype inst 等价于在 SQL*Plus 中执行 startup，对已运行的实例重复执行并无意义。
:startup
echo.
call :isRunning "%serviceName%"
set "SVC_UP=%errorlevel%"
call :isRunning "%listenerName%"
set "LSNR_UP=%errorlevel%"

if "%SVC_UP%%LSNR_UP%"=="00" (
    echo Warning: Oracle services are already started
    exit /B 1
)
if "%LSNR_UP%"=="1" (
    echo.Startup %listenerName%...
    net start "%listenerName%"
    if errorlevel 1 (
        echo ERROR: Failed to start %listenerName%.
        exit /B 1
    )
)
if "%SVC_UP%"=="1" (
    echo.Startup %serviceName%...
    net start "%serviceName%"
    if errorlevel 1 (
        echo ERROR: Failed to start %serviceName%.
        exit /B 1
    )
)
echo.Oracle started successfully!
exit /B 0

:: 停止（先停监听器，再停主服务）
:shutdown
echo.
call :isRunning "%serviceName%"
set "SVC_UP=%errorlevel%"
call :isRunning "%listenerName%"
set "LSNR_UP=%errorlevel%"

if "%SVC_UP%%LSNR_UP%"=="11" (
    echo Warning: Oracle services are not started
    exit /B 1
)
if "%LSNR_UP%"=="0" (
    echo.Shutdown %listenerName%...
    net stop "%listenerName%"
    if errorlevel 1 (
        echo ERROR: Failed to stop %listenerName%.
        exit /B 1
    )
)
if "%SVC_UP%"=="0" (
    echo.Shutdown %serviceName%...
    net stop "%serviceName%"
    if errorlevel 1 (
        echo ERROR: Failed to stop %serviceName%.
        exit /B 1
    )
)
echo.Oracle stopped successfully!
exit /B 0

:: 重启（服务未运行时跳过停止步骤，直接启动）
:reboot
call :shutdown
if errorlevel 1 goto reboot_start
ping -n 5 127.0.0.1 > nul
:reboot_start
call :startup
exit /B 0

:: 退出到菜单
:quit
pause
goto menu

:: 检查服务是否存在（主服务与监听器均需存在）
:checkService
sc query "%serviceName%" > nul
if errorlevel 1 (
    echo ERROR: %serviceName% Service does not exist!
    pause
    exit /b 1
)
sc query "%listenerName%" > nul
if errorlevel 1 (
    echo ERROR: %listenerName% Service does not exist!
    pause
    exit /b 1
)
goto menu

:: 判断服务是否运行中（参数: 服务名，含 START_PENDING）
:: 返回: 0=运行中 1=未运行
:: 必须用 exit /B 返回调用方，不能用 goto 跳回 :quit——
:: goto 不会弹出 call 压入的返回地址，累积到 335 帧时 cmd 会中止整个批处理
:isRunning
sc query "%~1" | findstr /I /C:"RUNNING" /C:"START_PENDING" > nul
if errorlevel 1 exit /B 1
exit /B 0
