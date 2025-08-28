@echo off
echo Deleting bin and obj folders...

REM Delete all obj
for /d /r %%d in (obj) do (
    if exist "%%d" (
        echo Deleting %%d
        rmdir /s /q "%%d"
    )
)

REM Delete all bin
for /d /r %%d in (bin) do (
    if exist "%%d" (
        echo Deleting %%d
        rmdir /s /q "%%d"
    )
)

echo Done!
pause
