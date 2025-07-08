#!/bin/bash

set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HOOK_ID="helm-dependency-update"

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
    chart_dir=$(dirname "$chart_file")
    # Only include charts that have dependencies
    if grep -q "dependencies:" "$chart_file" 2>/dev/null; then
      charts+=("$chart_dir")
    fi
  done < <(find . -name "Chart.yaml" -type f -print0)

  if [ ${#charts[@]} -eq 0 ]; then
    echo "No Helm charts with dependencies found"
    exit 0
  fi

  # Parse arguments
  local skip_refresh=false
  local args=()
  
  for arg in $hook_config; do
    case $arg in
      --skip-refresh)
        skip_refresh=true
        ;;
      *)
        args+=("$arg")
        ;;
    esac
  done

  # Run helm dependency update on each chart
  for chart_dir in "${charts[@]}"; do
    echo "Running helm dependency update on chart: $chart_dir"
    
    local dep_cmd="helm dependency update"
    
    if [ "$skip_refresh" = true ]; then
      dep_cmd="$dep_cmd --skip-refresh"
    fi
    
    # Add any additional arguments
    for arg in "${args[@]}"; do
      dep_cmd="$dep_cmd $arg"
    done
    
    dep_cmd="$dep_cmd $chart_dir"
    
    if ! eval "$dep_cmd"; then
      echo "helm dependency update failed for chart: $chart_dir"
      exit_code=1
    else
      echo "helm dependency update completed for chart: $chart_dir"
    fi
  done

  if [ $exit_code -ne 0 ]; then
    echo "helm dependency update failed for one or more charts"
    exit $exit_code
  fi
  
  echo "helm dependency update completed for all charts"
}

main "$@"