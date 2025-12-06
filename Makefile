.PHONY: format lint build test clean help

# Default target
help:
	@echo "Available targets:"
	@echo "  format    - Format Swift code using swift-format"
	@echo "  lint      - Lint Swift code using swift-format"
	@echo "  build     - Build the project"
	@echo "  test      - Run tests"
	@echo "  clean     - Clean build artifacts"
	@echo "  help      - Show this help message"

# Format Swift code
format:
	@echo "Formatting Swift code..."
	swift format -i -r .

# Lint Swift code
lint:
	@echo "Linting Swift code..."
	swift format lint -r .

# Build the project
build:
	@echo "Building project..."
	swift build

# Run tests
test:
	@echo "Running tests..."
	swift test

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	swift package clean