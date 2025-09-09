@echo off
REM === Criar pasta ../tmp se não existir ===
if not exist ..\tmp (
    mkdir ..\tmp
)

REM === Remover repositório antigo se existir ===
if exist ..\tmp\actapp (
    echo Removendo repositório antigo...
    rmdir /s /q ..\tmp\actapp
)

REM === Clonar repositório ===
echo Clonando repositório actapp...
git clone https://github.com/tadeumaffeis/actapp.git ..\tmp\actapp

REM === Copiar pasta lib para ../lib ===
if exist ..\tmp\actapp\lib (
    echo Copiando pasta lib para ..\lib
    xcopy /E /I /Y ..\tmp\actapp\lib\*.jar ..\lib
) else (
    echo ERRO: Pasta ..\tmp\actapp\lib nao encontrada!
)

REM === Remover pasta ../tmp ===
if exist ..\tmp (
    echo Removendo pasta temporaria ../tmp...
    rmdir /s /q ..\tmp
)

echo.
echo === Atualização concluída ===
pause
