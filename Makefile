# Makefile for Meet PIP

# Variables
PROJECT_ROOT := $(shell pwd)
XCODE_PROJECT := meet-pip/meetpip.xcodeproj
XCODE_SCHEME := meetpip
DERIVED_DATA := meet-pip/DerivedData

.PHONY: all install build build-extension build-app setup clean help

help:
	@echo "Available commands:"
	@echo "  make install         - Install Node dependencies"
	@echo "  make build           - Build both extension and native app"
	@echo "  make build-extension - Build Chrome extension only"
	@echo "  make build-app       - Build Native macOS app only"
	@echo "  make setup           - Setup Native Messaging Host (requires .env with EXTENSION_ID)"
	@echo "  make clean           - Clean build artifacts"

install:
	npm install

build: build-extension build-app

build-extension:
	npm run build

build-app:
	xcodebuild -project "$(XCODE_PROJECT)" \
		-scheme "$(XCODE_SCHEME)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		-configuration Debug \
		$(if $(TEAM_ID),CODE_SIGN_IDENTITY="$(TEAM_ID)",) \
		build

setup:
	@if [ ! -f .env ]; then \
		echo "Error: .env file not found. Please copy .env.example to .env and set EXTENSION_ID."; \
		exit 1; \
	fi
	@chmod +x native-setup/install.sh
	@./native-setup/install.sh

clean:
	rm -rf dist
	rm -rf "$(DERIVED_DATA)"
