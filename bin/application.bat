@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem =====================================================================
rem  PATH/MINGW (se precisar do MinGW no PATH)
rem =====================================================================
if not defined MINGW_HOME set "MINGW_HOME=C:\MinGW"
set "PATH=%PATH%;%MINGW_HOME%\bin"

rem *
rem * Download JDK 21
rem *
IF EXIST ..\jdk-25.0.2 goto :CONTINUE_EXEC
.\wget -c https://download.oracle.com/java/25/latest/jdk-25_windows-x64_bin.zip
REM .\wget -c https://download.oracle.com/java/21/archive/jdk-21.0.2_windows-x64_bin.zip
IF %ERRORLEVEL% NEQ 0 goto :ERROR_JAVA_DOWNLOAD

rem *
rem * Descompactando o JDK 21
rem *
.\GnuWin32\bin\unzip jdk-25_windows-x64_bin.zip
IF %ERRORLEVEL% NEQ 0 goto :ERROR_UNZIP_JAVA

rem *
rem * Movendo o JDK 21
rem *
IF EXIST ..\jdk-25.0.2 rmdir /s /q ..\jdk-25.0.2
move jdk-25.0.2 ..\
del .\jdk-25_windows-x64_bin.zip

:CONTINUE_EXEC
echo *************************************
echo * Status: Java 25 found!            *
echo * Action: Download JDK 21...        *
echo *************************************

rem =========================
rem Executando aplicação
rem =========================
set "JAVA_HOME=..\jdk-25.0.2"
set "PATH=%CD%\%JAVA_HOME%\bin;%PATH%"

rem --- Monta CLASSPATH automaticamente com todos os .jar em ..\lib ---
set "CLASSPATH="
for %%F in ("..\lib\*.jar") do (
    if defined CLASSPATH (
        set "CLASSPATH=!CLASSPATH!;%%~fF"
    ) else (
        set "CLASSPATH=%%~fF"
    )
)

rem (opcional) garante que a pasta de logs exista
if not exist "..\logs" mkdir "..\logs"

echo %CLASSPATH%
start "" javaw -cp "!CLASSPATH!" br.gov.sp.fatec.itu.aa.main.ActivitiesApplication 1>>"..\logs\log" 2>>"..\logs\log.err"
REM java -cp "!CLASSPATH!" br.gov.sp.fatec.itu.aa.main.ActivitiesApplication
goto :EXIT

:ERROR_JAVA_DOWNLOAD
echo Erro no download do jdk 25
IF EXIST .\jdk-25_windows-x64_bin.zip del .\jdk-25_windows-x64_bin.zip
goto :EXIT

:ERROR_UNZIP_JAVA
echo Erro ao descompactar o jdk 25
IF EXIST .\jdk-25 rmdir /s /q .\jdk-25.0.2
goto :EXIT

:EXIT
del database-*
endlocal
