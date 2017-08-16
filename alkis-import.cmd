@echo off
call "%~dp0\o4w_env.bat"
call "%~dp0\gdal-dev-env.bat"
cd "%OSGEO4W_ROOT%\apps\alkis-import-dev"
start "ALKIS-Import" /B pythonw alkisImport.py
