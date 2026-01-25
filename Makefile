# Playdate Development Environment - Cross-Platform Makefile
# Supports: macOS, Linux, Windows (Git Bash/MSYS2)
# Run 'make help' for usage

SHELL := /bin/bash
PLAYDATE_DEV_ROOT := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
TEMPLATES_DIR := $(PLAYDATE_DEV_ROOT)/templates
EXAMPLES_DIR := $(PLAYDATE_DEV_ROOT)/examples

# Detect OS for cross-platform support
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    PLATFORM := macos
    SDK_PATH := $(HOME)/Developer/PlaydateSDK
    SED_INPLACE := sed -i ''
    OPEN_CMD := open -a
    SIMULATOR := $(SDK_PATH)/bin/Playdate Simulator.app
else ifeq ($(UNAME_S),Linux)
    PLATFORM := linux
    SDK_PATH := $(HOME)/PlaydateSDK
    SED_INPLACE := sed -i
    OPEN_CMD :=
    SIMULATOR := $(SDK_PATH)/bin/PlaydateSimulator
else ifneq (,$(findstring MINGW,$(UNAME_S)))
    PLATFORM := windows
    SDK_PATH := $(HOME)/Documents/PlaydateSDK
    SED_INPLACE := sed -i
    OPEN_CMD :=
    SIMULATOR := $(SDK_PATH)/bin/PlaydateSimulator.exe
else ifneq (,$(findstring MSYS,$(UNAME_S)))
    PLATFORM := windows
    SDK_PATH := $(HOME)/Documents/PlaydateSDK
    SED_INPLACE := sed -i
    OPEN_CMD :=
    SIMULATOR := $(SDK_PATH)/bin/PlaydateSimulator.exe
else
    PLATFORM := unknown
    SDK_PATH := $(HOME)/PlaydateSDK
    SED_INPLACE := sed -i
    OPEN_CMD :=
    SIMULATOR := $(SDK_PATH)/bin/PlaydateSimulator
endif

# Allow override via environment
SDK_PATH := $(or $(PLAYDATE_SDK_PATH),$(SDK_PATH))

# Default template
TEMPLATE ?= basic

.PHONY: help install new-project list-templates list-examples run-example clean clean-all clean-sdk platform-info

help:
	@echo "Playdate Development Environment ($(PLATFORM))"
	@echo ""
	@echo "Usage:"
	@echo "  make install                    - Install dependencies (SDK, tools)"
	@echo "  make new-project NAME=MyGame    - Create new project from template"
	@echo "  make new-project NAME=MyGame TEMPLATE=crank-game"
	@echo "  make list-templates             - Show available templates"
	@echo "  make list-examples              - Show example projects"
	@echo "  make run-example EX=hello-world - Build and run an example"
	@echo "  make clean                      - Remove build artifacts from repo"
	@echo "  make clean-all                  - Clean all (prompts for SDK removal)"
	@echo "  make platform-info              - Show platform detection info"
	@echo ""
	@echo "Templates: $(shell ls $(TEMPLATES_DIR))"

install:
	@$(PLAYDATE_DEV_ROOT)/install.sh

new-project:
ifndef NAME
	@echo "Error: NAME is required"
	@echo "Usage: make new-project NAME=MyGame [TEMPLATE=basic]"
	@exit 1
endif
	@if [ -d "$(NAME)" ]; then \
		echo "Error: Directory '$(NAME)' already exists"; \
		exit 1; \
	fi
	@if [ ! -d "$(TEMPLATES_DIR)/$(TEMPLATE)" ]; then \
		echo "Error: Template '$(TEMPLATE)' not found"; \
		echo "Available: $$(ls $(TEMPLATES_DIR))"; \
		exit 1; \
	fi
	@cp -r "$(TEMPLATES_DIR)/$(TEMPLATE)" "$(NAME)"
	@$(SED_INPLACE) "s/TemplateName/$(NAME)/g" "$(NAME)/source/pdxinfo"
	@SAFE=$$(echo "$(NAME)" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9'); \
		$(SED_INPLACE) "s/templatename/$$SAFE/g" "$(NAME)/source/pdxinfo"
	@echo "Created project: $(NAME) (template: $(TEMPLATE))"
	@echo ""
	@echo "Next steps:"
	@echo "  cd $(NAME)"
	@echo "  pdbr    # Build and run"

list-templates:
	@echo "Available templates:"
	@echo ""
	@for t in $(TEMPLATES_DIR)/*; do \
		name=$$(basename $$t); \
		echo "  $$name"; \
		if [ -f "$$t/source/main.lua" ]; then \
			head -5 "$$t/source/main.lua" | grep -E "^\s*--" | head -1 | sed 's/--\[\[//' | sed 's/--/    /'; \
		fi; \
	done
	@echo ""
	@echo "Usage: make new-project NAME=MyGame TEMPLATE=<template>"

list-examples:
	@echo "Example projects:"
	@echo ""
	@for e in $(EXAMPLES_DIR)/*; do \
		name=$$(basename $$e); \
		echo "  $$name"; \
	done
	@echo ""
	@echo "Usage: make run-example EX=<example>"

run-example:
ifndef EX
	@echo "Error: EX is required"
	@echo "Usage: make run-example EX=hello-world"
	@echo ""
	@$(MAKE) list-examples
	@exit 1
endif
	@if [ ! -d "$(EXAMPLES_DIR)/$(EX)" ]; then \
		echo "Error: Example '$(EX)' not found"; \
		$(MAKE) list-examples; \
		exit 1; \
	fi
	@echo "Building $(EX)..."
	@cd "$(EXAMPLES_DIR)/$(EX)" && pdc source output.pdx
	@echo "Launching simulator..."
ifeq ($(PLATFORM),macos)
	@open -a "$(SIMULATOR)" "$(EXAMPLES_DIR)/$(EX)/output.pdx"
else
	@"$(SIMULATOR)" "$(EXAMPLES_DIR)/$(EX)/output.pdx" &
endif

clean:
	@echo "Cleaning build artifacts..."
	@# Clean example build outputs
	@find $(EXAMPLES_DIR) -name "*.pdx" -type d -exec rm -rf {} + 2>/dev/null || true
	@# Clean template build outputs (shouldn't exist but just in case)
	@find $(TEMPLATES_DIR) -name "*.pdx" -type d -exec rm -rf {} + 2>/dev/null || true
	@# Clean SDK download artifacts
ifeq ($(PLATFORM),macos)
	@rm -f $(HOME)/Developer/PlaydateSDK*.zip 2>/dev/null || true
	@rm -f $(HOME)/Developer/PlaydateSDK*.pkg 2>/dev/null || true
	@rm -rf $(HOME)/Developer/__MACOSX 2>/dev/null || true
else
	@rm -f $(HOME)/PlaydateSDK*.zip 2>/dev/null || true
	@rm -f $(HOME)/PlaydateSDK*.tar.gz 2>/dev/null || true
endif
	@echo "Cleaned build artifacts and SDK download files"

clean-sdk:
	@echo "This will remove the Playdate SDK from $(SDK_PATH)"
	@read -p "Are you sure? [y/N] " confirm && \
		if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
			rm -rf "$(SDK_PATH)" && \
			echo "Playdate SDK removed"; \
		else \
			echo "Cancelled"; \
		fi

clean-all: clean
	@echo ""
	@if [ -d "$(SDK_PATH)" ]; then \
		read -p "Remove Playdate SDK at $(SDK_PATH)? [y/N] " confirm && \
		if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
			rm -rf "$(SDK_PATH)" && \
			echo "Playdate SDK removed"; \
		else \
			echo "SDK kept"; \
		fi; \
	else \
		echo "No SDK installation found"; \
	fi
	@echo ""
	@echo "Clean complete"

platform-info:
	@echo "Platform Detection"
	@echo "=================="
	@echo "  Detected OS:    $(PLATFORM)"
	@echo "  uname -s:       $(UNAME_S)"
	@echo "  SDK Path:       $(SDK_PATH)"
	@echo "  Simulator:      $(SIMULATOR)"
	@echo "  sed command:    $(SED_INPLACE)"
	@echo ""
	@echo "Environment:"
	@echo "  PLAYDATE_SDK_PATH: $(PLAYDATE_SDK_PATH)"
	@echo "  HOME:              $(HOME)"
