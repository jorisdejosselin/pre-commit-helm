#!/bin/bash

set -e

# Script metadata (used for debugging if needed)
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HOOK_ID="helm-docs"

function main() {
  local -r hook_config="$*"
  local exit_code=0

  # Check if helm-docs is installed
  if ! command -v helm-docs &> /dev/null; then
    echo "Error: helm-docs is not installed or not in PATH"
    echo "Install it with: go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest"
    exit 1
  fi

  # Find all Chart.yaml files to determine chart directories
  local charts=()
  while IFS= read -r -d '' chart_file; do
    local chart_dir
    chart_dir=$(dirname "$chart_file")
    charts+=("$chart_dir")
  done < <(find . -name "Chart.yaml" -type f -print0)

  if [ ${#charts[@]} -eq 0 ]; then
    echo "No Helm charts found (no Chart.yaml files)"
    exit 0
  fi

  # Parse arguments
  local args=()

  for arg in $hook_config; do
    args+=("$arg")
  done

  # Run helm-docs on each chart
  for chart_dir in "${charts[@]}"; do
    echo "Running helm-docs on chart: $chart_dir"

    local docs_cmd="helm-docs"

    # Add chart directory
    docs_cmd="$docs_cmd --chart-search-root=$chart_dir"

    # Add any additional arguments
    for arg in "${args[@]}"; do
      docs_cmd="$docs_cmd $arg"
    done

    if ! eval "$docs_cmd"; then
      echo "helm-docs failed for chart: $chart_dir"
      exit_code=1
    else
      echo "helm-docs completed for chart: $chart_dir"
    fi
  done

  if [ $exit_code -ne 0 ]; then
    echo "helm-docs failed for one or more charts"
    exit $exit_code
  fi

  echo "helm-docs completed for all charts"
}

main "$@"
