docker run -e "ACCEPT_EULA=Y" -v sqlvolumeglasgow:/var/opt/mssql -e "SA_PASSWORD=Passw0rd" -p 12433:1433 --name glasgow -d --hostname glasgow microsoft/mssql-server-linux:2017-latest

docker run -e "ACCEPT_EULA=Y" -v sqlvolumeedinburgh:/var/opt/mssql -e "SA_PASSWORD=Passw0rd" -p 12435:1433 --name edinburgh -d --hostname edinburgh microsoft/mssql-server-linux:2017-latest

docker run -e "ACCEPT_EULA=Y" -v sqlvolumemanchester:/var/opt/mssql -e "SA_PASSWORD=Passw0rd" -p 12434:1433 --name manchester -d --hostname manchester microsoft/mssql-server-linux:2017-latest

docker ps -a


pause