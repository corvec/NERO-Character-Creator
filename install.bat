@echo off

mkdir "C:\Program Files\NERO Character Creator"

copy creator\* "C:\Program Files\NERO Character Creator"

copy shortcuts\* "%userprofile%\Desktop"
copy shortcuts\* "%userprofile%\Start Menu"

copy qt\* C:\Windows\System32