@echo off
call "%~dp0\o4w_env.bat"
cd /d "%OSGEO4W_ROOT%\apps\@PKG@"
start "ALKIS-Import" /B pythonw alkisImport.py
