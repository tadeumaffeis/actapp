@echo off
setlocal EnableExtensions

rem ============================================================================
rem  ActApp Update Script
rem  Finalidade:
rem    - Clonar temporariamente o repositório actapp
rem    - Copiar os arquivos .jar da pasta lib para o diretório local de libs
rem    - Limpar arquivos temporários ao final
rem ============================================================================

rem ----------------------------------------------------------------------------
rem Configuração inicial
rem ----------------------------------------------------------------------------
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%" >nul 2>&1

set "REPO_URL=https://github.com/tadeumaffeis/actapp.git"
set "TMP_DIR=..\tmp"
set "REPO_DIR=%TMP_DIR%\actapp"
set "SOURCE_LIB_DIR=%REPO_DIR%\lib"
set "TARGET_LIB_DIR=..\lib"

rem ----------------------------------------------------------------------------
rem Validação de dependências
rem ----------------------------------------------------------------------------
where git >nul 2>&1
if errorlevel 1 (
    call :logError "Git não encontrado no PATH. Instale o Git ou ajuste a variável PATH."
    goto :FAIL
)

where xcopy >nul 2>&1
if errorlevel 1 (
    call :logError "XCOPY não encontrado no sistema."
    goto :FAIL
)

rem ----------------------------------------------------------------------------
rem Garantia da pasta temporária
rem ----------------------------------------------------------------------------
if not exist "%TMP_DIR%" (
    call :logInfo "Criando diretório temporário: %TMP_DIR%"
    mkdir "%TMP_DIR%"
    if errorlevel 1 (
        call :logError "Falha ao criar o diretório temporário."
        goto :FAIL
    )
)

rem ----------------------------------------------------------------------------
rem Remoção de repositório temporário anterior
rem ----------------------------------------------------------------------------
if exist "%REPO_DIR%" (
    call :logInfo "Removendo repositório temporário anterior..."
    rmdir /s /q "%REPO_DIR%"
    if exist "%REPO_DIR%" (
        call :logError "Não foi possível remover o diretório temporário anterior."
        goto :FAIL
    )
)

rem ----------------------------------------------------------------------------
rem Clonagem do repositório
rem ----------------------------------------------------------------------------
call :logInfo "Clonando repositório actapp..."
git clone "%REPO_URL%" "%REPO_DIR%"
if errorlevel 1 (
    call :logError "Falha ao clonar o repositório."
    goto :FAIL
)

if not exist "%REPO_DIR%" (
    call :logError "O diretório do repositório não foi criado após o clone."
    goto :FAIL
)

rem ----------------------------------------------------------------------------
rem Validação da origem dos arquivos
rem ----------------------------------------------------------------------------
if not exist "%SOURCE_LIB_DIR%" (
    call :logError "Pasta de bibliotecas não encontrada: %SOURCE_LIB_DIR%"
    goto :FAIL
)

if not exist "%SOURCE_LIB_DIR%\*.jar" (
    call :logError "Nenhum arquivo .jar encontrado em %SOURCE_LIB_DIR%"
    goto :FAIL
)

rem ----------------------------------------------------------------------------
rem Garantia da pasta de destino
rem ----------------------------------------------------------------------------
if not exist "%TARGET_LIB_DIR%" (
    call :logInfo "Criando diretório de destino: %TARGET_LIB_DIR%"
    mkdir "%TARGET_LIB_DIR%"
    if errorlevel 1 (
        call :logError "Falha ao criar o diretório de destino."
        goto :FAIL
    )
)

rem ----------------------------------------------------------------------------
rem Cópia dos arquivos .jar
rem ----------------------------------------------------------------------------
call :logInfo "Copiando arquivos .jar para %TARGET_LIB_DIR%..."
xcopy "%SOURCE_LIB_DIR%\*.jar" "%TARGET_LIB_DIR%\" /E /I /Y >nul
if errorlevel 1 (
    call :logError "Falha ao copiar os arquivos .jar."
    goto :FAIL
)

rem ----------------------------------------------------------------------------
rem Limpeza
rem ----------------------------------------------------------------------------
call :cleanup

echo.
call :logInfo "Atualização concluída com sucesso."
goto :END_OK

rem ============================================================================
rem Funções auxiliares
rem ============================================================================

:cleanup
if exist "%TMP_DIR%" (
    call :logInfo "Removendo diretório temporário..."
    rmdir /s /q "%TMP_DIR%" >nul 2>&1
)
exit /b 0

:logInfo
echo [INFO] %~1
exit /b 0

:logError
echo [ERROR] %~1
exit /b 0

:FAIL
echo.
call :logError "A atualização não foi concluída."
call :cleanup
goto :END_ERROR

:END_OK
popd >nul 2>&1
endlocal
pause
exit /b 0

:END_ERROR
popd >nul 2>&1
endlocal
pause
exit /b 1
