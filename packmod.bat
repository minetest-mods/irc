@echo off

echo Detecting directories...
set srcdir=.
set bindir=Build
if exist CMakeLists.txt goto fnd_dir
set srcdir=..
set bindir=.
if exist ..\CMakeLists.txt goto fnd_dir
echo Error: Couldn't find CMakeLists.txt.
goto done

:fnd_dir

set lib=%bindir%\src\luasocket\libluasocket.dll
if exist %lib% goto fnd_lib
rem # It's impossible to use *.so files on Windows, so we skip that check.
echo Error: Couldn't find luasocket lib.
echo Did you compile before running this script?
goto done

set dir=%srcdir%/irc

md %dir%

echo "Copying files...";

copy %srcdir%/src/luairc/irc.lua %dir%
if errorlevel 1 goto copyerr
copy %srcdir%/src/luairc/irc %dir%
if errorlevel 1 goto copyerr
copy %srcdir%/doc/LICENSE-LuaIRC.txt %dir%
if errorlevel 1 goto copyerr

copy %srcdir%/src/luasocket/ftp.lua %dir%
if errorlevel 1 goto copyerr
copy %srcdir%/src/luasocket/http.lua %dir%
if errorlevel 1 goto copyerr
copy %srcdir%/src/luasocket/ltn12.lua %dir%
if errorlevel 1 goto copyerr
copy %srcdir%/src/luasocket/mime.lua %dir%
if errorlevel 1 goto copyerr
copy %srcdir%/src/luasocket/smtp.lua %dir%
if errorlevel 1 goto copyerr
copy %srcdir%/src/luasocket/socket.lua %dir%
if errorlevel 1 goto copyerr
copy %srcdir%/src/luasocket/tp.lua %dir%
if errorlevel 1 goto copyerr
copy %srcdir%/src/luasocket/url.lua %dir%
if errorlevel 1 goto copyerr
copy %srcdir%/doc/LICENSE-luasocket.txt %dir%
if errorlevel 1 goto copyerr
copy %lib% %dir%
if errorlevel 1 goto copyerr

copy %srcdir%/src/init.lua
if errorlevel 1 goto copyerr
copy %srcdir%/README.txt
if errorlevel 1 goto copyerr
copy %srcdir%/doc/LICENSE.txt
if errorlevel 1 goto copyerr

goto ok

:copyerr
echo Error: failed to copy files
goto done

:ok
echo "Operation completed successfully!";

:done
