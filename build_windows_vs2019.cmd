@echo off
submodules\bx\tools\bin\windows\genie vs2019

echo Check Visual Studio version
IF EXIST "c:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE" (
echo Using Visual Studio 2019 Professional Path
set "VISUALSTUDIO19PATH=c:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE"
) else (
echo Using Visual Studio 2019 Community Path
set "VISUALSTUDIO19PATH=c:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE"
)

IF EXIST "%VISUALSTUDIO19PATH%" (
echo Building ozz-animation Debug in Visual Studio 2019
"%VISUALSTUDIO19PATH%\devenv" ".build\projects\vs2019\ozz-animation.sln" /Build "Debug|x64"
echo ErrorLevel:%ERRORLEVEL%
IF %ERRORLEVEL% EQU 0 (
   echo Build successful!
) else (
   echo Build failed!
)
echo Building ozz-animation Release in Visual Studio 2019
"%VISUALSTUDIO19PATH%\devenv" ".build\projects\vs2019\ozz-animation.sln" /Build "Release|x64"
echo ErrorLevel:%ERRORLEVEL%
IF %ERRORLEVEL% EQU 0 (
   echo Build successful!
) else (
   echo Build failed!
)
) else (
echo Visual Studio 2019 not found! Open 'submodules\ozz-animation\.build\projects\vs2019\ozz-animation.sln' yourself and build it with your own version (NOTE you'll need to change vs2019 above to your installed version)
)

pause