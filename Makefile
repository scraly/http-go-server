GO   := go

DIRS_TO_CLEAN:=
FILES_TO_CLEAN:=

ifeq ($(origin GO), undefined)
  GO:=$(shell which go)
endif
ifeq ($(GO),)
  $(error Could not find 'go' in path. Please install go, or if already installed either add it to your path or set GO to point to its directory)
endif

pkgs  = $(shell GOFLAGS=-mod=vendor $(GO) list ./... | grep -vE -e /vendor/ -e /pkg/swagger/)
pkgDirs = $(shell GOFLAGS=-mod=vendor $(GO) list -f {{.Dir}} ./... | grep -vE -e /vendor/ -e /pkg/swagger/)
DIR_OUT:=/tmp

GOLANGCI:=$(shell command -v golangci-lint 2> /dev/null)
WWHRD:=$(shell command -v wwhrd 2> /dev/null)

GO_EXCLUDE := /vendor/|.pb.go|.gen.go
GO_FILES_CMD := find . -name '*.go' | grep -v -E '$(GO_EXCLUDE)'

#-------------------------
# Final targets
#-------------------------
.PHONY: dev

## Execute development pipeline
dev: license generate format lint.fast build

#-------------------------
# Download libraries and tools
#-------------------------
.PHONY: get.tools

## Retrieve tools packages
get.tools:
	# License checker
	go get -u github.com/frapposelli/wwhrd
 	# linter
	go get -u github.com/golangci/golangci-lint/cmd/golangci-lint

#-------------------------
# Code generation
#-------------------------
.PHONY: generate

## Generate go code
generate:
	@echo "==> generating go code"
	GOFLAGS=-mod=vendor $(GO) generate $(pkgs)

#-------------------------
# Checks
#-------------------------
.PHONY: format license license.csv lint.fast lint.full lint.sonar stats.loc

check: format license lint.full

## Apply code format, import reorganization and code simplification on source code
format:
	@echo "==> formatting code"
	@$(GO) fmt $(pkgs)
	@echo "==> clean imports"
	@goimports -w $(pkgDirs)
	@echo "==> simplify code"
	@gofmt -s -w $(pkgDirs)

## Check external license usage
license:
ifndef WWHRD
	$(error "Please install wwhrd! make get-tools")
endif
	@echo "==> license check"
	wwhrd check

## Launch linter
lint.fast:
ifndef GOLANGCI
	$(error "Please install golangci! make get-tools")
endif
	@echo "==> linters (fast)"
	@golangci-lint run -v --fast $(pkgDirs)

## Validate code
lint.full:
ifndef GOLANGCI
	$(error "Please install golangci! make get-tools")
endif
	@echo "==> linters (slow)"
	@golangci-lint run -v $(pkgDirs)

#-------------------------
# Build artefacts
#-------------------------
.PHONY: build build.http-server-go

## Build all binaries
build:
	$(GO) build -o bin/http-go-server internal/main.go

## Compress all binaries
pack:
	@echo ">> packing all binaries"
	@upx -7 -qq bin/*

#-------------------------
# Target: depend
#-------------------------
.PHONY: depend vendor.check depend.status depend.update depend.cleanlock depend.update.full

## Use go modules
depend: depend.tidy depend.verify depend.vendor

depend.tidy:
	@echo "==> Running dependency cleanup"
	$(GO) mod tidy -v

depend.verify:
	@echo "==> Verifying dependencies"
	$(GO) mod verify

depend.vendor:
	@echo "==> Freezing dependencies"
	$(GO) mod vendor

depend.update:
	@echo "==> Update go modules"
	$(GO) get -u -v

depend.update.full: depend.cleanlock depend.update

#-------------------------
# Target: clean
#-------------------------

## Clean build files
clean: clean.go
	rm -rf $(DIRS_TO_CLEAN)
	rm -f $(FILES_TO_CLEAN)

clean.go: ; $(info cleaning...)
	$(eval GO_CLEAN_FLAGS := -i -r)
	$(GO) clean $(GO_CLEAN_FLAGS)

#-------------------------
# Target: help
#-------------------------

# COLORS
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)


TARGET_MAX_CHAR_NUM=20
## Show help
help:
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

#-------------------------
# Target: swagger.validate
#-------------------------
.PHONY: swagger.validate

swagger.validate:
	swagger validate pkg/swagger/swagger.yml

#-------------------------
# Target: swagger.doc
#-------------------------
.PHONY: swagger.doc

swagger.doc:
	docker run -i yousan/swagger-yaml-to-html < pkg/swagger/swagger.yml > doc/index.html