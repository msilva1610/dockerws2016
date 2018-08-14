# app image
FROM microsoft/aspnet
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV BING_MAPS_KEY bing_maps_key

WORKDIR C:\\nerd-dinner

RUN Remove-Website -Name 'Default Web Site';
RUN New-Website -Name 'nerd-dinner' -Port 80 -PhysicalPath 'c:\nerd-dinner' -ApplicationPool '.NET v4.5'

RUN & c:\windows\system32\inetsrv\appcmd.exe unlock config /section:system.webServer/handlers

COPY nerd-dinner C:\\nerd-dinner
