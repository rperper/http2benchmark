# README.md
## Install the HTTP/3 package
Client machine will need to run following command to build h2load to support http/3 protocol.
```
http2benchmark/http3/script/prepare_client.sh
```
On the server machine you only need to run the command to build Quiche for Nginx server: 
```
http2benchmark/http3/script/prepare_server.sh
```

## How to test
Run command to benchmark LSWS, OpenLiteSpeed, Nginx and h2o
```
bash benchmark.sh http3.profile
```
