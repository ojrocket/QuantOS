BUILD_DIR := build
ISO_SCRIPT := $(BUILD_DIR)/build-iso.sh

.PHONY: build help

help:
	@echo "Usage: make build"
	@echo "       make help"

build:
	@bash $(ISO_SCRIPT) --help
