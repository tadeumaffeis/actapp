@echo off
set PATH=%PATH%;%MINGW_HOME%

rem *
rem * Download JDK 21
rem *
IF EXIST ..\jdk-21.0.2 goto :CONTINUE_EXEC
.\wget -c https://download.oracle.com/java/21/archive/jdk-21.0.2_windows-x64_bin.zip
IF %ERRORLEVEL% NEQ 0 got :ERROR_JAVA_DOWNLOAD

rem *
rem * Descompactando o JDK 21
rem *
.\GnuWin32\bin\unzip jdk-21.0.2_windows-x64_bin.zip
IF %ERRORLEVEL% NEQ 0 got :ERROR_UNZIP_JAVA

rem *
rem * Movendo o JDK 21
rem *
IF EXIST ..\jdk-21.0.2 rmdir /s /q ..\jdk-21.0.2
move jdk-21.0.2 ..\
del .\jdk-21.0.2_windows-x64_bin.zip

:CONTINUE_EXEC
echo *************************************
echo * Status: Java 21 found!            *
echo * Action: Download JDK 21...        *
echo *************************************
rem *
rem * executando aplicação
rem *
set JAVA_HOME=..\jdk-21.0.2
set MINGW_HOME=C:\MinGW
set PATH=%PATH%;%CD%\%JAVA_HOME%\bin
set CLASSPATH=..\lib\ActivitiesApplication.jar
set CLASSPATH=%CLASSPATH%;..\lib\EventDispatcher.jar
set CLASSPATH=%CLASSPATH%;..\lib\jackson-core-2.14.0-SNAPSHOT.jar
set CLASSPATH=%CLASSPATH%;..\lib\javax.json-1.1.4.jar
set CLASSPATH=%CLASSPATH%;..\lib\json-simple-1.0-SNAPSHOT.jar
set CLASSPATH=%CLASSPATH%;..\lib\JSONExerciseGenerate.jar
set CLASSPATH=%CLASSPATH%;..\lib\sqlite-jdbc-3.37.2.jar
start javaw -cp %CLASSPATH% br.gov.sp.fatec.itu.aa.main.ActivitiesApplication 1>>..\logs\log 2>>..\logs\log.err
goto :EXIT

:ERROR_JAVA_DOWNLOAD
echo Erro no download do jdk 21
IF EXIST .\jdk-21.0.2_windows-x64_bin.zip del .\jdk-21.0.2_windows-x64_bin.zip
goto :EXIT

:ERROR_UNZIP_JAVA
echo Erro ao descompactar o jdk 21
IF EXIST .\jdk-21.0.2 rmdir /s /q .\jdk-21.0.2
goto :EXIT

:EXIT
del database-*