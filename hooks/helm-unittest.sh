#!/bin/bash

set -e

# Script metadata (used for debugging if needed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly HOOK_ID="helm-unittest"

function main() {
  local -r hook_config="$*"
  local exit_code=0

  # Check if helm is installed
  if ! command -v helm &> /dev/null; then
    echo "Error: helm is not installed or not in PATH"
    exit 1
  fi

  # Check if unittest plugin is available
  plugin_available=false
  if helm plugin list | grep -q "unittest"; then
    plugin_available=true
  fi

  # Alternative check: try to run helm unittest --help to see if it's available
  if [ "$plugin_available" = false ]; then
    if helm unittest --help &>/dev/null; then
      plugin_available=true
    fi
  fi

  # If still not available, try to install it
  if [ "$plugin_available" = false ]; then
    echo "helm-unittest plugin not found, attempting to install..."

    # Try to install the plugin
    if helm plugin install https://github.com/helm-unittest/helm-unittest; then
      echo "Successfully installed helm-unittest plugin"
      plugin_available=true
    else
      echo "Error: Failed to install helm-unittest plugin"
      echo "Manual installation: helm plugin install https://github.com/helm-unittest/helm-unittest"
      exit 1
    fi
  fi

  if [ "$plugin_available" = false ]; then
    echo "Error: helm-unittest plugin is not available"
    exit 1
  fi

  # Find all Chart.yaml files to determine chart directories
  local charts=()
  while IFS= read -r -d '' chart_file; do
    local chart_dir
    chart_dir=$(dirname "$chart_file")
    # Only include charts that have tests directory
    if [ -d "$chart_dir/tests" ]; then
      charts+=("$chart_dir")
    fi
  done < <(find . -name "Chart.yaml" -type f -print0)

  if [ ${#charts[@]} -eq 0 ]; then
    echo "No Helm charts with tests found (no Chart.yaml files with tests/ directory)"
    exit 0
  fi

  # Parse arguments
  local args=()

  for arg in $hook_config; do
    args+=("$arg")
  done

  # Run helm unittest on each chart
  for chart_dir in "${charts[@]}"; do
    echo "Running helm unittest on chart: $chart_dir"

    # Update dependencies if Chart.lock exists or dependencies are defined
    if [ -f "$chart_dir/Chart.lock" ] || grep -q "dependencies:" "$chart_dir/Chart.yaml" 2>/dev/null; then
      echo "Updating dependencies for chart: $chart_dir"
      if ! helm dependency update "$chart_dir" &>/dev/null; then
        echo "Warning: Failed to update dependencies for chart: $chart_dir"
      fi
    fi

    local unittest_cmd="helm unittest"

    # Add any additional arguments
    for arg in "${args[@]}"; do
      unittest_cmd="$unittest_cmd $arg"
    done

    unittest_cmd="$unittest_cmd $chart_dir"

    if ! eval "$unittest_cmd"; then
      echo "helm unittest failed for chart: $chart_dir"
      exit_code=1
    else
      echo "helm unittest passed for chart: $chart_dir"
    fi
  done

  if [ $exit_code -ne 0 ]; then
    echo "helm unittest failed for one or more charts"
    exit $exit_code
  fi

  echo "helm unittest passed for all charts"
}

main "$@"
