::export.bat


:: cleanup export directories
del /Q export\*
del /Q export_fixed\*

:: export texture files


cd tatex

@echo off
setlocal
for %%A in ("*") do (
  set "fname=%%~A"
 
  call set "fname2=%%fname:.tga=.BMP%%"
  call set "fname2=%%fname2:.bmp=.BMP%%"

  call convert -alpha off  "%%fname%%" BMP:"..\export\%%fname2:00.=.%%"

)

endlocal

cd..
