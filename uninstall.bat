@echo off

del "C:\Program Files\NERO Character Creator\*"
rmdir "C:\Program Files\NERO Character Creator"

del "%userprofile%\Start Menu\NERO Character Creator.lnk"
del "%userprofile%\Desktop\NERO Character Creator.lnk"

del C:\Windows\System32\libsmokeqt.dll
del C:\Windows\System32\mingwm10.dll
del C:\Windows\System32\QtCore4.dll
del C:\Windows\System32\QtNetwork4.dll
del C:\Windows\System32\QtSql4.dll
del C:\Windows\System32\rbrcc.exe
del C:\Windows\System32\QtGui4.dll
del C:\Windows\System32\QtOpenGL4.dll
del C:\Windows\System32\QtSvg4.dll
del C:\Windows\System32\rbuic4.exe
del C:\Windows\System32\QtXml4.dll
