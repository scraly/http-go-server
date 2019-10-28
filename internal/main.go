package main

import (
	"log"

	// "github.com/go-openapi/swag"
	"github.com/go-openapi/loads"
	"github.com/scraly/http-go-server/pkg/swagger/server/restapi"
	// "github.com/scraly/http-go-server/pkg/swagger/server/models"
	// "github.com/scraly/http-go-server/pkg/swagger/server/restapi/operations"
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
	defer server.Shutdown()

	server.Port = "8080"

	// Implement the handler functionality.
	// As all we need to do is give an implementation to the interface
	// we can just override the `api` method giving it a method with a valid
	// signature (we didn't need to have this implementation here, it could
	// even come from a different package).
	// api.GetHostnameHandler = operations.GetHostnameHandlerFunc(
	// 	func(params operations.GetHostnameParams) middleware.Responder {
	// 		response, err := os.Hostname()
	// 		if err != nil {
	// 			return operations.NewGetHostnameDefault(500).WithPayload(&models.Error{
	// 				Code:    500,
	// 				Message: swag.String("failed to retrieve hostname"),
	// 			})
	// 		}

	// 		return operations.NewGetHostnameOK().WithPayload(response)
	// 	})

	// Start listening using having the handlers and port
	// already set up.
	if err := server.Serve(); err != nil {
		log.Fatalln(err)
	}
}
