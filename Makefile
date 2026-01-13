.PHONY: help lint test bump prepare-release list-charts clean

# Default target
help:
	@echo "Cloudscript Helm Charts - Available Commands:"
	@echo ""
	@echo "  make lint CHART=<chart-name>           - Lint a specific chart"
	@echo "  make lint-all                          - Lint all charts"
	@echo "  make test CHART=<chart-name>           - Test template rendering"
	@echo "  make test-all                          - Test all charts"
	@echo "  make bump CHART=<chart-name> TYPE=<type> - Bump chart version (major|minor|patch)"
	@echo "  make prepare-release CHART=<chart-name> - Prepare chart for release"
	@echo "  make list-charts                       - List all available charts"
	@echo "  make clean                             - Clean temporary files"
	@echo ""
	@echo "Examples:"
	@echo "  make lint CHART=deploy-apps"
	@echo "  make test CHART=deploy-apps"
	@echo "  make bump CHART=deploy-apps TYPE=minor"
	@echo "  make prepare-release CHART=deploy-apps"

# Lint a specific chart
lint:
ifndef CHART
	$(error CHART is not set. Usage: make lint CHART=chart-name)
endif
	@echo "Linting $(CHART)..."
	@helm lint ./$(CHART)

# Lint all charts
lint-all:
	@echo "Linting all charts..."
	@for chart in agent-script deploy-apps dumpscript k8s-monitoring-app; do \
		echo ""; \
		echo "==> Linting $$chart..."; \
		helm lint ./$$chart || exit 1; \
	done
	@echo ""
	@echo "✓ All charts passed lint check!"

# Test template rendering
test:
ifndef CHART
	$(error CHART is not set. Usage: make test CHART=chart-name)
endif
	@echo "Testing template rendering for $(CHART)..."
	@helm template test ./$(CHART) --debug

# Test all charts
test-all:
	@echo "Testing all charts..."
	@for chart in agent-script deploy-apps dumpscript k8s-monitoring-app; do \
		echo ""; \
		echo "==> Testing $$chart..."; \
		helm template test ./$$chart --debug > /dev/null || exit 1; \
	done
	@echo ""
	@echo "✓ All charts render successfully!"

# Bump chart version
bump:
ifndef CHART
	$(error CHART is not set. Usage: make bump CHART=chart-name TYPE=minor)
endif
ifndef TYPE
	$(error TYPE is not set. Usage: make bump CHART=chart-name TYPE=minor)
endif
	@./.github/scripts/bump-version.sh $(CHART) $(TYPE)

# Prepare a chart for release
prepare-release:
ifndef CHART
	$(error CHART is not set. Usage: make prepare-release CHART=chart-name)
endif
	@./.github/scripts/prepare-release.sh $(CHART)

# List all charts
list-charts:
	@echo "Available charts:"
	@echo ""
	@for chart in agent-script deploy-apps dumpscript k8s-monitoring-app; do \
		if [ -f "./$$chart/Chart.yaml" ]; then \
			version=$$(grep '^version:' "./$$chart/Chart.yaml" | awk '{print $$2}'); \
			description=$$(grep '^description:' "./$$chart/Chart.yaml" | cut -d':' -f2- | sed 's/^[[:space:]]*//'); \
			echo "  📦 $$chart (v$$version)"; \
			echo "     $$description"; \
			echo ""; \
		fi \
	done

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find . -name "*.tgz" -type f -delete
	@find . -name "charts/*.tgz" -type f -delete
	@find . -name "Chart.lock" -type f -delete
	@find . -type d -name "charts" -exec rm -rf {} + 2>/dev/null || true
	@echo "✓ Cleanup complete!"

# Install dependencies for a chart
deps:
ifndef CHART
	$(error CHART is not set. Usage: make deps CHART=chart-name)
endif
	@echo "Installing dependencies for $(CHART)..."
	@cd ./$(CHART) && helm dependency update

# Package a chart
package:
ifndef CHART
	$(error CHART is not set. Usage: make package CHART=chart-name)
endif
	@echo "Packaging $(CHART)..."
	@helm package ./$(CHART) -d /tmp/
	@echo "✓ Package created in /tmp/"

# Dry-run install
install-dry-run:
ifndef CHART
	$(error CHART is not set. Usage: make install-dry-run CHART=chart-name)
endif
	@echo "Dry-run install for $(CHART)..."
	@helm install test-release ./$(CHART) --dry-run --debug

# Quick check before commit
pre-commit:
	@echo "Running pre-commit checks..."
	@make lint-all
	@make test-all
	@echo ""
	@echo "✓ All pre-commit checks passed!"
