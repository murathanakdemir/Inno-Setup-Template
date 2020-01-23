@echo off

for /f "delims=" %%a in ('wmic OS Get localdatetime ^| find "."') do set DateTime=%%a

set Yr=%DateTime:~0,4%
set Mon=%DateTime:~4,2%
set Day=%DateTime:~6,2%
set Hr=%DateTime:~8,2%
set Min=%DateTime:~10,2%
set Sec=%DateTime:~12,2%
set BackupName= "sense-manager-backup_%Day%-%Mon%-%Yr%_(%Hr%.%Min%.%Sec%)"

cd "C:\Program Files\InnoSetupTemplate\mysql\bin"
mysqldump -u %1 -p%2 %3 > "C:\ProgramData\InnoSetupTemplate\Backup\%BackupName%.sql"