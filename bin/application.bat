rem @echo off
del database-*
set MINGW_HOME=C:\MinGW
set JAVA_HOME=..\java\jdk-21
set PATH=%PATH%;%MINGW_HOME%
set CLASSPATH=..\lib\ActivitiesApplication.jar
set CLASSPATH=%CLASSPATH%;..\lib\EventDispatcher.jar
set CLASSPATH=%CLASSPATH%;..\lib\jackson-core-2.14.0-SNAPSHOT.jar
set CLASSPATH=%CLASSPATH%;..\lib\javax.json-1.1.4.jar
set CLASSPATH=%CLASSPATH%;..\lib\json-simple-1.0-SNAPSHOT.jar
set CLASSPATH=%CLASSPATH%;..\lib\JSONExerciseGenerate.jar
set CLASSPATH=%CLASSPATH%;..\lib\sqlite-jdbc-3.37.2.jar
start javaw -cp %CLASSPATH% br.gov.sp.fatec.itu.aa.main.ActivitiesApplication 1>>..\logs\log 2>>..\logs\log.err
