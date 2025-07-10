#!/bin/bash

set -e

# Script metadata (used for debugging if needed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly HOOK_ID="helm-template"

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
  local debug_mode=false
  local args=()

  if [[ "${HELM_TEMPLATE_DEBUG:-false}" == "true" ]]; then
    debug_mode=true
  fi

  for arg in $hook_config; do
    case $arg in
      --debug)
        debug_mode=true
        ;;
      *)
        args+=("$arg")
        ;;
    esac
  done

  # Run helm template on each chart
  for chart_dir in "${charts[@]}"; do
    echo "Running helm template on chart: $chart_dir"

    # Update dependencies if Chart.lock exists or dependencies are defined
    if [ -f "$chart_dir/Chart.lock" ] || grep -q "dependencies:" "$chart_dir/Chart.yaml" 2>/dev/null; then
      echo "Updating dependencies for chart: $chart_dir"
      if ! helm dependency update "$chart_dir" &>/dev/null; then
        echo "Warning: Failed to update dependencies for chart: $chart_dir"
      fi
    fi

    local template_cmd="helm template test-release"
    if [ "$debug_mode" = true ]; then
      template_cmd="$template_cmd --debug"
    fi

    # Add any additional arguments
    for arg in "${args[@]}"; do
      template_cmd="$template_cmd $arg"
    done

    template_cmd="$template_cmd $chart_dir"

    # Run template command and capture output
    if ! eval "$template_cmd" > /tmp/helm-template-output.yaml 2>&1; then
      echo "helm template failed for chart: $chart_dir"
      cat /tmp/helm-template-output.yaml
      exit_code=1
    else
      echo "helm template passed for chart: $chart_dir"

      # Validate that the output contains valid YAML
      if ! python3 -c "import yaml; yaml.safe_load_all(open('/tmp/helm-template-output.yaml'))" 2>/dev/null; then
        echo "Warning: Generated templates for $chart_dir may contain invalid YAML"
      fi
    fi
  done

  # Clean up temporary file
  rm -f /tmp/helm-template-output.yaml

  if [ $exit_code -ne 0 ]; then
    echo "helm template failed for one or more charts"
    exit $exit_code
  fi

  echo "helm template passed for all charts"
}

main "$@"
