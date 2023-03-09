call "%OSGEO4W_ROOT%\bin\o4w_env.bat"


if not %OSGEO4W_MENU_LINKS%==0 if not exist "%OSGEO4W_STARTMENU%" mkdir "%OSGEO4W_STARTMENU%"
if not %OSGEO4W_DESKTOP_LINKS%==0 if not exist "%OSGEO4W_DESKTOP%" mkdir "%OSGEO4W_DESKTOP%"

if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\norGIS ALKIS Import.lnk" "%OSGEO4W_ROOT%\bin\bgspawn.exe" "%OSGEO4W_ROOT%\bin\alkis-import.cmd" . "" 1 "%OSGEO4W_ROOT%\\apps\\alkis-import\\logo.ico"
if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\norGIS ALKIS Import.lnk" "%OSGEO4W_ROOT%\bin\bgspawn.exe" "%OSGEO4W_ROOT%\bin\alkis-import.cmd" . "" 1 "%OSGEO4W_ROOT%\\apps\\alkis-import\\logo.ico"

if not exist %OSGEO4W_ROOT%\apps\alkis-import\config.sql echo -- Konfiguration hier>%OSGEO4W_ROOT%\apps\alkis-import\config.sql
