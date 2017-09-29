@echo off
Powershell.exe Set-ExecutionPolicy unrestricted
Start-Process Powershell.exe "-ExecutionPolicy ByPass -noninteractive -windowstyle hidden -File \\file\share\logsetup\elevate.ps1"
