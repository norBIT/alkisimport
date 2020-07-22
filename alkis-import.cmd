@echo off
call "%~dp0\o4w_env.bat"
call "%~dp0\qt5_env.bat"
call "%~dp0\py3_env.bat"
call "%~dp0\gdal-dev-env.bat"
cd "%OSGEO4W_ROOT%\apps\alkis-import-gid7"
start "ALKIS-Import" /B pythonw alkisImport.py
