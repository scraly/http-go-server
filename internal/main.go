package main

import (
	"log"

	"github.com/go-openapi/loads"
	"github.com/go-openapi/runtime/middleware"
	"github.com/scraly/http-go-server/pkg/swagger/server/restapi"

	"github.com/scraly/http-go-server/pkg/swagger/server/restapi/operations"
)

// func main() {
// 	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
// 		fmt.Fprintf(w, "Hello, %q", html.EscapeString(r.URL.Path))
// 	})

// 	log.Println("Listening on localhost:8080")
// 	log.Fatal(http.ListenAndServe(":8080", nil))
// }

func main() {

	// Initialize Swagger
	swaggerSpec, err := loads.Analyzed(restapi.SwaggerJSON, "")
	if err != nil {
		log.Fatalln(err)
	}

	api := operations.NewHelloAPI(swaggerSpec)
	server := restapi.NewServer(api)

	defer func() {
		if err := server.Shutdown(); err != nil {
			// error handle
			log.Fatalln(err)
		}
	}()

	server.Port = 8080

	// Implement the CheckHealth handler
	api.CheckHealthHandler = operations.CheckHealthHandlerFunc(
		func(user operations.CheckHealthParams) middleware.Responder {
			return operations.NewCheckHealthOK().WithPayload("OK")
		})

	// Implement the GetHelloUser handler
	api.GetHelloUserHandler = operations.GetHelloUserHandlerFunc(
		func(user operations.GetHelloUserParams) middleware.Responder {
			return operations.NewGetHelloUserOK().WithPayload("Hello " + user.User + "!")
		})

	// Start server which listening
	if err := server.Serve(); err != nil {
		log.Fatalln(err)
	}
}
