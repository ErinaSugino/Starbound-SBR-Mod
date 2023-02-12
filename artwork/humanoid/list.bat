@echo off
set /p dirpath="Select directory: "
dir "%dirpath%" /b/a-d > "%dirpath%\list.txt"
exit
