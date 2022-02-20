@ECHO OFF

REM source: https://github.com/alain-riedinger/lua53/blob/master/src/Build-lua.cmd

REM where MSVC envirnoment configuration script (a .bat file) is located
SET MSVC_ENV_BAT_PATH=%1
REM where lua source files (e.g. C/H files) are located
SET SRC_DIR=%2
SET INC_DIR=%3
REM which target is it (32 or 64-bit)
SET TARGET=%4

CALL %MSVC_ENV_BAT_PATH%

PUSHD %SRC_DIR%
FOR /F %%f in ('dir /b *.rc') do RC %%f
CL -MP -MD -O2 -c -DLUA_BUILD_AS_DLL /I%INC_DIR% *.c

REM need to copy this to avoid _main conflict when building lua53.exe as luac.obj also defines main entry point
MOVE /Y luac.obj luac.o

LINK -subsystem:console -dll -implib:..\lib\%TARGET%\lua53.lib -out:..\dist\%TARGET%\lua53.dll *.obj ..\res\lua_dll.res
LINK -out:..\dist\%TARGET%\lua53.exe lua.obj ..\res\lua.res ..\lib\%TARGET%\lua53.lib
LIB -out:..\lib\%TARGET%\lua53-static.lib *.obj
REM link with the satic library to produce luac53.exe - static doesn't need lua53.dll in order to run
LINK -out:..\dist\%TARGET%\luac53.exe luac.o ..\res\lua_simple.res ..\lib\%TARGET%\lua53-static.lib

DEL ..\dist\%TARGET%\*.lib
DEL ..\dist\%TARGET%\*.exp
POPD
