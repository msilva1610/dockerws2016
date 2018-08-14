[Weekly Windows Dockerfile #12](https://blog.sixeyed.com/windows-weekly-dockerfile-12-nerddinner/)

# Notas de entendimento

Diferente do conceito tradicional de uma aplicação APS.NET, no docker devemos rodar uma aplicação por caontainer. Por isso é mantido apenas um application pool por aplicação. Os demais sites e appplication pool são removidos.

O comando docker run está sendo executdo lendo sempre um dockerfile para fazer o build da imagem e subir um container a partir dessa imagem. Cada pasta de exemplo possui seu dockerfile para fazer o build da imagem. 

## Dockerfile em analise
```
# escape=`
FROM sixeyed/msbuild:netfx-4.5.2-webdeploy-10.0.14393.1198 AS builder

WORKDIR C:\src\NerdDinner
COPY src\NerdDinner\packages.config .
RUN nuget restore packages.config -PackagesDirectory ..\packages

COPY src C:\src
RUN msbuild NerdDinner.csproj /p:OutputPath=c:\out\NerdDinner `
        /p:DeployOnBuild=true /p:VSToolsPath=C:\MSBuild.Microsoft.VisualStudio.Web.targets.14.0.0.3\tools\VSToolsPath

# app image
FROM microsoft/aspnet:windowsservercore-10.0.14393.1198
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV BING_MAPS_KEY bing_maps_key
WORKDIR C:\nerd-dinner

RUN Remove-Website -Name 'Default Web Site'; `
    New-Website -Name 'nerd-dinner' `
                -Port 80 -PhysicalPath 'c:\nerd-dinner' `
                -ApplicationPool '.NET v4.5'

RUN & c:\windows\system32\inetsrv\appcmd.exe `
      unlock config `
      /section:system.webServer/handlers

COPY --from=builder C:\out\NerdDinner\_PublishedWebsites\NerdDinner C:\nerd-dinner

```

## Destravar o web.config
O padrão o web.config são modificados para ajustar a aplicação. A seção system.webserver no web.config fica travada por default. Para destravar usa-se a instrução abaixo dentro do dockerfile.

```
RUN & c:\windows\system32\inetsrv\appcmd.exe `
      unlock config `
      /section:system.webServer/handlers
```

## Docker run em execução com suporte do Dockerfile

```
docker container run -d -P dockeronwindows/ch02-nerd-dinner

```

Para executar a execução do Container ativos, digite:
```
docker container ls
```

Para avaliar as configurações de um container, digite:
```
docker container inspect <id> ou <container-name> 
```

Para popupar tempo procurando a infoirmação desejada é mais fácil filtrar no json a campo desejado. Exemplo para encontrar um IP:

```
docker container inspect --format '{{.NetworkSettings.Networks.nat.IPAddress }}' demo
```

Para verificar o que mantem o entrypoint do container:

```
docker container inspect --format '{{.Config.Entrypoint}}' <conatiner-name ou container-id>
```

# Capitulo 3 - Movendo uma aplicação asp.net para container

## Alterando a forma como  o IIS grava as logs

## Dockerfile em analise
```
# escape=`
FROM microsoft/iis:windowsservercore
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# configure IIS to write a global log file:
RUN Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log' -n 'centralLogFileMode' -v 'CentralW3C'; `
    Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'truncateSize' -v 4294967295; `
    Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'period' -v 'MaxSize'; `
    Set-WebConfigurationProperty -p 'MACHINE/WEBROOT/APPHOST' -fi 'system.applicationHost/log/centralW3CLogFile' -n 'directory' -v 'c:\iislog'

ENTRYPOINT ["powershell"]
CMD Start-Service W3SVC; `
    Invoke-WebRequest http://localhost -UseBasicParsing | Out-Null; `
    netsh http flush logbuffer | Out-Null; `
    Get-Content -path 'c:\iislog\W3SVC\u_extend1.log' -Tail 1 -Wait 
```

O ultimo CMD acima possui 4 instruções:

1. Inicia o serviço do IIS (W3SVC)
2. Faz a primeira requisição HTTP para iniciar o arquivo de log
3. Faz um flush na log permitindo que o powershell escute a saída e mantém a escrita padrão no disco
4. Ler o conteúdo de cada entrada na log com Tail mode e exibe na console

Executando o container no modo normal

```
docker container run -d -P --name log-watcher dockeronwindows/ch03-iislog-watcher
```

O comando acima deu erro. O sistema não estava construindo a imagem e utilizando como normalmente. então, executei:
```
docker build -t  dockeronwindows/ch03-iislog-watcher .
```

Depois do docker build acima. Executei novamente:
```
docker container run -d -P --name log-watcher dockeronwindows/ch03-iislog-watcher
``` 

Container criado com sucesso.

A log do IIS armazena em memória as requisições e derraga as linhas no arquivo quando atinge 64k. Para não ficar esperando a solução é executar o comando abaiaco em outra janela.

```
docker container exec log-watcher netsh http flush logbuffer
```

Depois verificar novamente as log com o comando:
```
docker container logs -f log-watcher
```



# Capitulo CH03 - 
