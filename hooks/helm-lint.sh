#!/bin/bash

set -e

# Script metadata (used for debugging if needed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly HOOK_ID="helm-lint"

function main() {
  local -r hook_config="$*"
  local exit_code=0

  # Check if helm is installed
  if ! command -v helm &> /dev/null; then
    echo "Error: helm is not installed or not in PATH"
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
  local strict_mode=false
  local args=()

  if [[ "${HELM_LINT_STRICT:-false}" == "true" ]]; then
    strict_mode=true
  fi

  for arg in $hook_config; do
    case $arg in
      --strict)
        strict_mode=true
        ;;
      *)
        args+=("$arg")
        ;;
    esac
  done

  # Run helm lint on each chart
  for chart_dir in "${charts[@]}"; do
    echo "Running helm lint on chart: $chart_dir"

    local lint_cmd="helm lint"
    if [ "$strict_mode" = true ]; then
      lint_cmd="$lint_cmd --strict"
    fi

    # Add any additional arguments
    for arg in "${args[@]}"; do
      lint_cmd="$lint_cmd $arg"
    done

    lint_cmd="$lint_cmd $chart_dir"

    if ! eval "$lint_cmd"; then
      echo "helm lint failed for chart: $chart_dir"
      exit_code=1
    else
      echo "helm lint passed for chart: $chart_dir"
    fi
  done

  if [ $exit_code -ne 0 ]; then
    echo "helm lint failed for one or more charts"
    exit $exit_code
  fi

  echo "helm lint passed for all charts"
}

main "$@"
