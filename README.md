# http-go-server

This repo contains a simple/basic HTTP server in Go, with a basic code organization.
We use:
* net/http package to start and serve HTTP server
* Gorilla mux to handle routes
* Swagger in lorder to serve a REST API compliant with OpenAPI specs

## Pre-requisits

Install Go in 1.13 version minimum.

## Build the app

`$ go build -o bin/http-go-server internal/main.go`

or

`$ make build`

## Run the app

`$ ./bin/http-go-server`

## Test the app

```
$ curl http://localhost:8080/healthz
OK

$ curl http://localhost:8080/hello/aurelie

```

### Request & Response Examples

Swagger doc: [http-go-server](https://github.com/scraly/http-go-server/doc/index.html)

|                 URL					 | Port | HTTP Method			       | Operation														    |
|:-------------------------:|:--------:|:-----------------------:|------------------------------------------------------------------------|
| /healthz							 | 8080 | GET       |  Test if the app is running							    |
| /hello/{name}							 | 8080 | GET       |  Returns message with {name} provided in the query							    |						    |


`$ curl localhost:8080/hello/aurelie`

## Generate swagger files

After editing `pkg/swagger/swagger.yml` file you need to generate swagger files again:

`$ make gen.swagger`

## Test swagger file validity

`$ make swagger.validate`

## Generate swagger documentation

`$ make swagger.doc`