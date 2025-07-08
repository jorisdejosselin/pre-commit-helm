#!/bin/bash

set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HOOK_ID="helm-security"

function main() {
  local -r hook_config="$*"
  local exit_code=0
  
  # Check if trivy is installed
  if ! command -v trivy &> /dev/null; then
    echo "Error: trivy is not installed or not in PATH"
    echo "Install it from: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
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
    chart_dir=$(dirname "$chart_file")
    charts+=("$chart_dir")
  done < <(find . -name "Chart.yaml" -type f -print0)

  if [ ${#charts[@]} -eq 0 ]; then
    echo "No Helm charts found (no Chart.yaml files)"
    exit 0
  fi

  # Parse arguments
  local severity="${TRIVY_SEVERITY:-HIGH,CRITICAL}"
  local args=()
  
  for arg in $hook_config; do
    case $arg in
      --severity)
        shift
        severity="$1"
        shift
        ;;
      --severity=*)
        severity="${arg#--severity=}"
        ;;
      *)
        args+=("$arg")
        ;;
    esac
  done

  # Run trivy security scan on each chart
  for chart_dir in "${charts[@]}"; do
    echo "Running security scan on chart: $chart_dir"
    
    # Update dependencies if Chart.lock exists or dependencies are defined
    if [ -f "$chart_dir/Chart.lock" ] || grep -q "dependencies:" "$chart_dir/Chart.yaml" 2>/dev/null; then
      echo "Updating dependencies for chart: $chart_dir"
      if ! helm dependency update "$chart_dir" &>/dev/null; then
        echo "Warning: Failed to update dependencies for chart: $chart_dir"
      fi
    fi
    
    # Create temporary directory for rendered templates
    local temp_dir=$(mktemp -d)
    
    # Render templates
    if ! helm template test-release "$chart_dir" --output-dir "$temp_dir" &>/dev/null; then
      echo "Failed to render templates for chart: $chart_dir"
      rm -rf "$temp_dir"
      exit_code=1
      continue
    fi
    
    # Run trivy config scan on rendered templates
    local trivy_cmd="trivy config --severity $severity --exit-code 1"
    
    # Add any additional arguments
    for arg in "${args[@]}"; do
      trivy_cmd="$trivy_cmd $arg"
    done
    
    trivy_cmd="$trivy_cmd $temp_dir"
    
    if ! eval "$trivy_cmd"; then
      echo "Security scan failed for chart: $chart_dir"
      exit_code=1
    else
      echo "Security scan passed for chart: $chart_dir"
    fi
    
    # Clean up temporary directory
    rm -rf "$temp_dir"
  done

  if [ $exit_code -ne 0 ]; then
    echo "Security scan failed for one or more charts"
    exit $exit_code
  fi
  
  echo "Security scan passed for all charts"
}

main "$@"