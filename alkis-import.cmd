@echo off
SET OSGEO4W_ROOT=C:\OSGeo4W
call "%OSGEO4W_ROOT%"\bin\o4w_env.bat
PATH=%CD%\gdal-dev\bin;%PATH%
SET GDAL_DATA=%CD%\gdal-dev\share\gdal
SET PYTHONPATH=%CD%\gdal-dev\pymod;%PYTHONPATH%
cd %PROGRAMFILES%\norBIT\ALKIS-Import
start "ALKIS-Import" /B pythonw alkisImport.py
