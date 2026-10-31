@echo off
chcp 936 >nul 2>&1
setlocal EnableDelayedExpansion
title Anki 便携版 - 一键升级

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "APPDIR=%ROOT%\App"

echo.
echo ============================================================
echo                Anki 便携版 - 一键升级
echo ============================================================
echo  程序目录：%ROOT%
echo.

rem ============ 1. Anki 必须完全退出 ============
tasklist /nh /fi "imagename eq Anki.exe" 2>nul | findstr /i "Anki.exe" >nul
if not errorlevel 1 (
    echo  [停止] 检测到 Anki 正在运行。
    echo.
    echo         请先完全关闭 Anki，包括右下角托盘图标里的那个；
    echo         如果你还装着官方安装版，它也一并退出。
    echo         然后重新双击本脚本。
    echo.
    pause
    exit /b 1
)

rem ============ 2. 查找升级包 ============
set "MSI="
set "N=0"
for /f "delims=" %%F in ('dir /b /s "%ROOT%\anki-*.msi" 2^>nul') do (
    set "MSI=%%F"
    set /a N+=1
)

if "%N%"=="0" (
    echo  [停止] 没有找到安装包。
    echo.
    echo         请到 github.com/ankitects/anki/releases/latest
    echo         下载文件名形如 anki-x.y.z-win-x64.msi 的文件，
    echo         原样放进本文件夹下的「升级包」文件夹，
    echo         然后再双击运行本脚本。
    echo.
    if not exist "%ROOT%\升级包" md "%ROOT%\升级包" >nul 2>&1
    pause
    exit /b 1
)

if not "%N%"=="1" (
    echo  [停止] 找到 %N% 个安装包，无法判断该用哪个。
    echo.
    echo         请只保留要升级的那一个，把其余的移走：
    echo.
    for /f "delims=" %%F in ('dir /b /s "%ROOT%\anki-*.msi" 2^>nul') do echo            %%~nxF
    echo.
    pause
    exit /b 1
)

for %%A in ("%MSI%") do set "MSINAME=%%~nxA"
echo !MSINAME! | findstr /i "arm64" >nul
if not errorlevel 1 (
    echo  [停止] 这个包是 Windows ARM64 版，不能在普通的 64 位电脑上使用。
    echo.
    echo         请重新下载文件名里带 win-x64 的那个。
    echo.
    pause
    exit /b 1
)
for %%A in ("%MSI%") do set /a MSISIZE=%%~zA/1048576

rem ============ 3. 读取当前版本 ============
set "CURVER=未知"
for /f "delims=" %%D in ('dir /b /ad "%APPDIR%\app\anki-*.dist-info" 2^>nul') do set "CURVER=%%D"
if not "!CURVER!"=="未知" (
    set "CURVER=!CURVER:anki-=!"
    set "CURVER=!CURVER:.dist-info=!"
)
set "OLDVER=!CURVER!"

echo  当前版本：!CURVER!
echo  升级包  ：!MSINAME!  (!MSISIZE! MB)
echo.
echo  升级只替换 App 里的程序文件，Data 里的牌组和复习进度不会被动。
echo.

set "ANS="
set /p "ANS=确认开始升级？输入 Y 回车继续，直接回车取消："
if /i not "!ANS:~0,1!"=="y" (
    echo.
    echo  已取消，什么都没改。
    echo.
    pause
    exit /b 0
)

rem ============ 4. 备份 Data ============
set "ANS="
set /p "ANS=是否先备份 Data 文件夹？建议备份，直接回车即备份 (Y/n)："
if /i "!ANS:~0,1!"=="n" (
    echo  已跳过备份。
) else (
    call :do_backup
    if errorlevel 1 (
        echo.
        pause
        exit /b 1
    )
)

rem ============ 5. 解包 ============
call :do_extract
if errorlevel 1 (
    echo.
    pause
    exit /b 1
)

rem ============ 6. 替换 ============
call :do_swap
if errorlevel 1 (
    echo.
    pause
    exit /b 1
)

rem ============ 7. 收尾 ============
if defined TMPD if exist "!TMPD!" rd /s /q "!TMPD!" >nul 2>&1

set "NEWVER=未知"
for /f "delims=" %%D in ('dir /b /ad "%APPDIR%\app\anki-*.dist-info" 2^>nul') do set "NEWVER=%%D"
if not "!NEWVER!"=="未知" (
    set "NEWVER=!NEWVER:anki-=!"
    set "NEWVER=!NEWVER:.dist-info=!"
)

echo.
echo ============================================================
echo   升级完成： !OLDVER!  变成  !NEWVER!
echo ============================================================
echo.
echo   Data 文件夹没有被改动，牌组和复习进度都在。
echo   建议现在启动一次 Anki 确认正常，第一次启动会稍慢一点。
echo.

set "ANS="
set /p "ANS=现在启动 Anki 吗？ (Y/n)："
if /i not "!ANS:~0,1!"=="n" (
    start "" "%APPDIR%\Anki.exe" --base "%ROOT%\Data"
)
echo.
pause
exit /b 0


rem ============================================================
rem  子过程
rem ============================================================

:do_backup
set "BK=%ROOT%\Data-backup"
set /a IDX=1
:bk_loop
if exist "%BK%%IDX%" (
    set /a IDX+=1
    goto bk_loop
)
set "BK=%BK%%IDX%"
echo.
echo   正在备份 Data 到 !BK! ...
robocopy "%ROOT%\Data" "!BK!" /E /NFL /NDL /NJH /NJS /NP /R:1 /W:1 >nul
if errorlevel 8 (
    echo   [警告] 备份时有文件读取失败，可能被其他程序占用。
    echo          建议关闭 Anki 及相关程序后重试，或手动复制 Data 文件夹。
    exit /b 1
)
echo   备份完成。
exit /b 0


:do_extract
set "TMPD=%TEMP%\anki-upgrade-%RANDOM%%RANDOM%"
md "!TMPD!" >nul 2>&1
echo.
echo   正在解包安装包，大约需要 1-2 分钟，请不要关闭这个窗口...
start /wait "" msiexec.exe /a "!MSI!" /qn TARGETDIR="!TMPD!" /l*v "!TMPD!\extract.log"
if errorlevel 1 (
    echo   [失败] 解包出错，错误码 !errorlevel!。
    echo          请确认这个 msi 是官方原版、没有下载损坏，
    echo          或者换一个下载源重新下载后重试。
    echo          当前版本没有被改动，可以放心退出。
    if exist "!TMPD!" rd /s /q "!TMPD!" >nul 2>&1
    exit /b 1
)

set "SRC="
for /f "delims=" %%F in ('dir /b /s "!TMPD!\Anki.exe" 2^>nul') do if not defined SRC set "SRC=%%~dpF"
if defined SRC if "!SRC:~-1!"=="\" set "SRC=!SRC:~0,-1!"
if not defined SRC (
    echo   [失败] 解包结果里找不到 Anki.exe，这个包的结构和预期不一致。
    echo          当前版本没有被改动。
    if exist "!TMPD!" rd /s /q "!TMPD!" >nul 2>&1
    exit /b 1
)
if not exist "!SRC!\app_packages\" (
    echo   [失败] 解包结果不完整，缺少 app_packages 文件夹。
    echo          当前版本没有被改动。
    if exist "!TMPD!" rd /s /q "!TMPD!" >nul 2>&1
    exit /b 1
)
echo   解包完成。
exit /b 0


:do_swap
set "BAK=%ROOT%\App.bak"
if exist "!BAK!" rd /s /q "!BAK!" >nul 2>&1
echo.
echo   正在替换程序文件，大约需要 30 秒...
move "%APPDIR%" "!BAK!" >nul
if errorlevel 1 (
    echo   [失败] 无法重命名 App 文件夹，可能有程序正在占用里面的文件。
    echo          请重启电脑后重试。当前版本没有被改动。
    exit /b 1
)
md "%APPDIR%" >nul 2>&1
robocopy "!SRC!" "%APPDIR%" /E /NFL /NDL /NJH /NJS /NP /R:1 /W:1 >nul
set "RC=!errorlevel!"
if !RC! GEQ 8 (
    call :do_rollback
    exit /b 1
)
if not exist "%APPDIR%\Anki.exe" (
    call :do_rollback
    exit /b 1
)
if not exist "%APPDIR%\app_packages\" (
    call :do_rollback
    exit /b 1
)
rd /s /q "!BAK!" >nul 2>&1
echo   替换完成。
exit /b 0


:do_rollback
echo.
echo   [失败] 新版本安装不完整，正在自动还原旧版本...
rd /s /q "%APPDIR%" >nul 2>&1
move "!BAK!" "%APPDIR%" >nul
echo   已还原，你的 Anki 仍然是可以正常使用的旧版本。
exit /b 0
