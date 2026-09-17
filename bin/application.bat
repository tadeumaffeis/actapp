@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================================
rem  Activities Application Launcher
rem  Finalidade:
rem    - Garantir a presença do JDK local
rem    - Montar o classpath automaticamente
rem    - Iniciar a aplicação Java com logs
rem ============================================================================

rem ----------------------------------------------------------------------------
rem Configurações gerais
rem ----------------------------------------------------------------------------
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%" >nul 2>&1

set "APP_NAME=ActivitiesApplication"
set "MAIN_CLASS=br.gov.sp.fatec.itu.aa.main.ActivitiesApplication"

set "JDK_VERSION=25.0.4.1"
set "JDK_FOLDER_NAME=jdk-%JDK_VERSION%"
set "JDK_ARCHIVE_NAME=jdk-25_windows-x64_bin.zip"
set "JDK_DOWNLOAD_URL=https://download.oracle.com/java/25/latest/%JDK_ARCHIVE_NAME%"

set "JDK_TARGET_DIR=..\%JDK_FOLDER_NAME%"
set "LIB_DIR=..\lib"
set "LOG_DIR=..\logs"

set "WGET_EXE=%SCRIPT_DIR%wget.exe"
set "UNZIP_EXE=%SCRIPT_DIR%GnuWin32\bin\unzip.exe"

if "%OS%"=="Windows_NT" (
    if exist ".\*.sh" del /f /q ".\*.sh" >nul 2>&1
)

rem ----------------------------------------------------------------------------
rem PATH auxiliar (MinGW), se necessário
rem ----------------------------------------------------------------------------
if not defined MINGW_HOME set "MINGW_HOME=C:\MinGW"
if exist "%MINGW_HOME%\bin" set "PATH=%PATH%;%MINGW_HOME%\bin"

rem ----------------------------------------------------------------------------
rem Validação de dependências
rem ----------------------------------------------------------------------------
if not exist "%WGET_EXE%" (
    call :logError "Dependência não encontrada: %WGET_EXE%"
    goto :FAIL
)

if not exist "%UNZIP_EXE%" (
    call :logError "Dependência não encontrada: %UNZIP_EXE%"
    goto :FAIL
)

rem ----------------------------------------------------------------------------
rem Garantia do JDK local
rem ----------------------------------------------------------------------------
if exist "%JDK_TARGET_DIR%" (
    call :logInfo "JDK %JDK_VERSION% localizado em %JDK_TARGET_DIR%."
    goto :CONFIGURE_JAVA
)

call :logInfo "JDK %JDK_VERSION% não encontrado. Iniciando download..."
call :downloadJdk
if errorlevel 1 goto :FAIL

call :extractJdk
if errorlevel 1 goto :FAIL

call :installJdk
if errorlevel 1 goto :FAIL

:CONFIGURE_JAVA
rem ----------------------------------------------------------------------------
rem Configuração do ambiente Java
rem ----------------------------------------------------------------------------
set "JAVA_HOME=%CD%\%JDK_TARGET_DIR%"
set "PATH=%JAVA_HOME%\bin;%PATH%"

if not exist "%JAVA_HOME%\bin\javaw.exe" (
    call :logError "javaw.exe não encontrado em %JAVA_HOME%\bin"
    goto :FAIL
)

rem ----------------------------------------------------------------------------
rem Garantia da pasta de logs
rem ----------------------------------------------------------------------------
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

rem ----------------------------------------------------------------------------
rem Montagem dinâmica do CLASSPATH
rem ----------------------------------------------------------------------------
if not exist "%LIB_DIR%" (
    call :logError "Diretório de bibliotecas não encontrado: %LIB_DIR%"
    goto :FAIL
)

set "CLASSPATH="
for %%F in ("%LIB_DIR%\*.jar") do (
    if defined CLASSPATH (
        set "CLASSPATH=!CLASSPATH!;%%~fF"
    ) else (
        set "CLASSPATH=%%~fF"
    )
)

if not defined CLASSPATH (
    call :logError "Nenhum arquivo .jar encontrado em %LIB_DIR%"
    goto :FAIL
)

call :logInfo "Inicializando %APP_NAME%..."
call :logInfo "JAVA_HOME=%JAVA_HOME%"

rem ----------------------------------------------------------------------------
rem Execução da aplicação
rem ----------------------------------------------------------------------------
start "" "%JAVA_HOME%\bin\javaw.exe" -cp "!CLASSPATH!" %MAIN_CLASS% 1>>"%LOG_DIR%\log" 1>>"%LOG_DIR%\log" 2>>"%LOG_DIR%\log.err"
if errorlevel 1 (
    call :logError "Falha ao iniciar a aplicação."
    goto :FAIL
)

goto :SUCCESS

rem ============================================================================
rem Funções
rem ============================================================================

:downloadJdk
call :logInfo "Baixando JDK de: %JDK_DOWNLOAD_URL%"
"%WGET_EXE%" -c "%JDK_DOWNLOAD_URL%"
if errorlevel 1 (
    call :logError "Erro no download do JDK."
    if exist "%JDK_ARCHIVE_NAME%" del /f /q "%JDK_ARCHIVE_NAME%" >nul 2>&1
    exit /b 1
)
exit /b 0

:extractJdk
call :logInfo "Descompactando %JDK_ARCHIVE_NAME%..."
"%UNZIP_EXE%" "%JDK_ARCHIVE_NAME%"
if errorlevel 1 (
    call :logError "Erro ao descompactar o JDK."
    exit /b 1
)
exit /b 0

:installJdk
call :logInfo "Instalando JDK em %JDK_TARGET_DIR%..."
if exist "%JDK_TARGET_DIR%" rmdir /s /q "%JDK_TARGET_DIR%" >nul 2>&1

if not exist "%JDK_FOLDER_NAME%" (
    call :logError "Pasta extraída não encontrada: %JDK_FOLDER_NAME%"
    exit /b 1
)

move "%JDK_FOLDER_NAME%" "..\" >nul
if errorlevel 1 (
    call :logError "Erro ao mover o JDK para o diretório de destino."
    exit /b 1
)

if exist "%JDK_ARCHIVE_NAME%" del /f /q "%JDK_ARCHIVE_NAME%" >nul 2>&1
exit /b 0

:logInfo
echo [INFO] %~1
exit /b 0

:logError
echo [ERROR] %~1
exit /b 0

:SUCCESS
call :logInfo "Aplicação iniciada com sucesso."
goto :CLEANUP

:FAIL
call :logError "Execução finalizada com erro."
goto :CLEANUP

:CLEANUP
del /f /q database-* >nul 2>&1
popd >nul 2>&1
endlocal
exit /b
