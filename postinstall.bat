REM get short path without blanks
for %%i in ("%OSGEO4W_ROOT%") do set O4W_ROOT=%%~fsi

if not %OSGEO4W_MENU_LINKS%==0 mkdir "%OSGEO4W_STARTMENU%"
if not %OSGEO4W_MENU_LINKS%==0 nircmd shortcut "%O4W_ROOT%\bin\nircmd.exe" "%OSGEO4W_STARTMENU%" "norGIS ALKIS Import (GID7)" "exec hide %O4W_ROOT%\bin\alkis-import-gid7.cmd" "%O4W_ROOT%\apps\alkis-import-gid7\logo.ico"
if not %OSGEO4W_DESKTOP_LINKS%==0 nircmd shortcut "%O4W_ROOT%\bin\nircmd.exe" "~$folder.desktop$" "norGIS ALKIS Import (GID7)" "exec hide %O4W_ROOT%\bin\alkis-import-gid7.cmd" "%O4W_ROOT%\apps\alkis-import-gid7\logo.ico"
