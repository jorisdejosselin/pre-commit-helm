#!/bin/bash

set -e

# Script metadata (used for debugging if needed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly HOOK_ID="helm-kubeval"

function main() {
  local -r hook_config="$*"
  local exit_code=0

  # Check if kubeval is installed
  if ! command -v kubeval &> /dev/null; then
    echo "Error: kubeval is not installed or not in PATH"
    echo "Install it from: https://github.com/instrumenta/kubeval"
    exit 1
  fi

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
  local kubernetes_version=""
  local args=()

  for arg in $hook_config; do
    case $arg in
      --kubernetes-version)
        shift
        kubernetes_version="$1"
        shift
        ;;
      --kubernetes-version=*)
        kubernetes_version="${arg#--kubernetes-version=}"
        ;;
      *)
        args+=("$arg")
        ;;
    esac
  done

  # Run kubeval on each chart
  for chart_dir in "${charts[@]}"; do
    echo "Running kubeval on chart: $chart_dir"

    # Update dependencies if Chart.lock exists or dependencies are defined
    if [ -f "$chart_dir/Chart.lock" ] || grep -q "dependencies:" "$chart_dir/Chart.yaml" 2>/dev/null; then
      echo "Updating dependencies for chart: $chart_dir"
      if ! helm dependency update "$chart_dir" &>/dev/null; then
        echo "Warning: Failed to update dependencies for chart: $chart_dir"
      fi
    fi

    # Create temporary file for rendered templates
    local temp_file
    temp_file=$(mktemp)

    # Render templates
    if ! helm template test-release "$chart_dir" > "$temp_file" 2>/dev/null; then
      echo "Failed to render templates for chart: $chart_dir"
      rm -f "$temp_file"
      exit_code=1
      continue
    fi

    # Run kubeval
    local kubeval_cmd="kubeval"

    if [ -n "$kubernetes_version" ]; then
      kubeval_cmd="$kubeval_cmd --kubernetes-version $kubernetes_version"
    fi

    # Add any additional arguments
    for arg in "${args[@]}"; do
      kubeval_cmd="$kubeval_cmd $arg"
    done

    kubeval_cmd="$kubeval_cmd $temp_file"

    if ! eval "$kubeval_cmd"; then
      echo "kubeval failed for chart: $chart_dir"
      exit_code=1
    else
      echo "kubeval passed for chart: $chart_dir"
    fi

    # Clean up temporary file
    rm -f "$temp_file"
  done

  if [ $exit_code -ne 0 ]; then
    echo "kubeval failed for one or more charts"
    exit $exit_code
  fi

  echo "kubeval passed for all charts"
}

main "$@"
