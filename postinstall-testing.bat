REM get short path without blanks
for %%i in ("%OSGEO4W_ROOT%") do set O4W_ROOT=%%~fsi

if not %OSGEO4W_MENU_LINKS%==0 mkdir "%OSGEO4W_STARTMENU%"
if not %OSGEO4W_MENU_LINKS%==0 xxmklink "%OSGEO4W_STARTMENU%\\norGIS ALKIS Import.lnk" "%OSGEO4W_ROOT%\\bin\\bgspawn.exe" "\\"%OSGEO4W_ROOT%\\bin\\alkis-import.cmd\\"" "" "" 1 "%OSGEO4W_ROOT%\\apps\\alkis-import\\logo.ico"
if not %OSGEO4W_DESKTOP_LINKS%==0 xxmklink "%OSGEO4W_DESKTOP%\\norGIS ALKIS Import.lnk" "%OSGEO4W_ROOT%\\bin\\bgspawn.exe" "\\"%OSGEO4W_ROOT%\\bin\\alkis-import.cmd\\"" "" "" 1 "%OSGEO4W_ROOT%\\apps\\alkis-import\\logo.ico"
