@echo off
setlocal
cd /d "%~dp0"
where py >nul 2>&1
if %ERRORLEVEL%==0 (
  py -3 "%~dp0stage01_reconcile.py"
  set RC=%ERRORLEVEL%
  goto :done
)
where python >nul 2>&1
if %ERRORLEVEL%==0 (
  python "%~dp0stage01_reconcile.py"
  set RC=%ERRORLEVEL%
  goto :done
)
echo Python 3 was not found.
set RC=9009
:done
echo.
echo Exit code: %RC%
echo Output is under %%USERPROFILE%%\Pastafarian_MATLAB_Polski_STAGE01_RECONCILE
pause
exit /b %RC%
