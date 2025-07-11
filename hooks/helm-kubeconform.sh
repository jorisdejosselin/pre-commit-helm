#!/bin/bash

set -e

# Script metadata (used for debugging if needed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly HOOK_ID="helm-kubeconform"

function main() {
  local -r hook_config="$*"
  local exit_code=0

  # Check if kubeconform is installed
  if ! command -v kubeconform &> /dev/null; then
    echo "Error: kubeconform is not installed or not in PATH"
    echo "Install it from: https://github.com/yannh/kubeconform"
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

  # Run kubeconform on each chart
  for chart_dir in "${charts[@]}"; do
    echo "Running kubeconform on chart: $chart_dir"

    # Update dependencies if Chart.lock exists or dependencies are defined
    if [ -f "$chart_dir/Chart.lock" ] || grep -q "dependencies:" "$chart_dir/Chart.yaml" 2>/dev/null; then
      echo "Updating dependencies for chart: $chart_dir"
      if ! helm dependency update "$chart_dir" &>/dev/null; then
        echo "Warning: Failed to update dependencies for chart: $chart_dir"
      fi
    fi

    # Create temporary directory for rendered templates
    local temp_dir
    temp_dir=$(mktemp -d)

    # Render templates to directory
    if ! helm template test-release "$chart_dir" --output-dir "$temp_dir" &>/dev/null; then
      echo "Failed to render templates for chart: $chart_dir"
      rm -rf "$temp_dir"
      exit_code=1
      continue
    fi

    # Run kubeconform
    local kubeconform_cmd="kubeconform -summary -verbose"

    if [ -n "$kubernetes_version" ]; then
      kubeconform_cmd="$kubeconform_cmd -kubernetes-version $kubernetes_version"
    fi

    # Add any additional arguments
    for arg in "${args[@]}"; do
      kubeconform_cmd="$kubeconform_cmd $arg"
    done

    # kubeconform can validate directories, so pass the temp directory
    kubeconform_cmd="$kubeconform_cmd $temp_dir"

    if ! eval "$kubeconform_cmd"; then
      echo "kubeconform failed for chart: $chart_dir"
      exit_code=1
    else
      echo "kubeconform passed for chart: $chart_dir"
    fi

    # Clean up temporary directory
    rm -rf "$temp_dir"
  done

  if [ $exit_code -ne 0 ]; then
    echo "kubeconform failed for one or more charts"
    exit $exit_code
  fi

  echo "kubeconform passed for all charts"
}

main "$@"
