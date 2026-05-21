@echo off
setlocal enabledelayedexpansion

:: -----------------------------------------------------------------------
:: imgui ? wyvrnpm publish matrix
::
:: Iterates every platform x renderer option combination (15 total) and
:: for each one runs:
::   1. wyvrnpm clean
::   2. wyvrnpm install     (bakes options into CMakePresets.json)
::   3. wyvrnpm build       (--clean, all 4 configs, cmake --install)
::   4. wyvrnpm publish     (uploads the ABI-specific artefact)
::
:: Each combination produces a distinct profileHash because the resolved
:: options (platform + renderer) fold into the hash. Publishing them all
:: is safe ? different hashes, no --force needed.
::
:: Usage:
::   publish_all_variants.bat [<publish-source-name>]
::
::   <publish-source-name>   Named source from `wyvrnpm configure list`.
::                           Omit to use the default configured source.
::
:: Requires: wyvrnpm >= 2.9.0  (for --all-configs)
:: -----------------------------------------------------------------------

set "SOURCE_ARG="
if not "%~1"=="" set "SOURCE_ARG=--source %~1"

echo.
echo  imgui publish matrix
echo  ==================================================
echo   docking  : true  (locked, always included)
echo   platform : glfw  win32  none
echo   renderer : directx12  directx11  opengl  vulkan  none
echo   configs  : Debug  Release  RelWithDebInfo  MinSizeRel
echo   total    : 15 combinations
if defined SOURCE_ARG (
    echo   source   : %~1
) else (
    echo   source   : ^(default^)
)
echo  ==================================================
echo.
echo  WARNING: This writes 15 artefacts to the shared registry.
echo  Press Ctrl+C to abort, or any key to begin.
pause > nul

set PASS=0
set FAIL=0
set "FAILED_LIST="

for %%P in (glfw win32 none) do (
    for %%R in (directx12 directx11 opengl vulkan none) do (
        call :run_combo %%P %%R
        if errorlevel 1 (
            set /a FAIL+=1
            set "FAILED_LIST=!FAILED_LIST!  platform=%%P / renderer=%%R!LF!"
        ) else (
            set /a PASS+=1
        )
    )
)

echo.
echo  ==================================================
echo   Results: %PASS% passed,  %FAIL% failed
if defined FAILED_LIST (
    echo.
    echo   Failed combinations:
    echo   %FAILED_LIST%
)
echo  ==================================================

if %FAIL% GTR 0 exit /b 1
exit /b 0


:: -----------------------------------------------------------------------
:run_combo
setlocal
set "P=%1"
set "R=%2"
set "OPT=-o imgui:platform=%P% -o imgui:renderer=%R%"

echo.
echo  ------ platform=%P%   renderer=%R% ------

echo [1/4] wyvrnpm clean
call wyvrnpm clean
if errorlevel 1 ( echo FAILED at clean & exit /b 1 )

echo [2/4] wyvrnpm install %OPT%
call wyvrnpm install %OPT%
if errorlevel 1 ( echo FAILED at install & exit /b 1 )

echo [3/4] wyvrnpm build --clean --install --all-configs
call wyvrnpm build --clean --install --all-configs
if errorlevel 1 ( echo FAILED at build & exit /b 1 )

echo [4/4] wyvrnpm publish %OPT% %SOURCE_ARG%
call wyvrnpm publish %OPT% %SOURCE_ARG%
if errorlevel 1 ( echo FAILED at publish & exit /b 1 )

echo  OK: platform=%P%   renderer=%R%
exit /b 0
