@echo off
call "%~dp0\o4w_env.bat"
cd "%OSGEO4W_ROOT%\apps\alkis-import"
start "ALKIS-Import" /B pythonw alkisImport.py
