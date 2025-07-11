# Contributing to pre-commit-helm

Thank you for your interest in contributing to pre-commit-helm! This document provides guidelines for contributing to the project.

## Development Setup

1. **Fork and clone the repository**:

   ```bash
   git clone https://github.com/jorisdejosselin/pre-commit-helm.git
   cd pre-commit-helm
   ```

2. **Install dependencies**:

   ```bash
   npm install
   ```

3. **Install pre-commit for development**:

   ```bash
   pip install pre-commit
   pre-commit install
   pre-commit install --hook-type commit-msg
   ```

## Making Changes

### Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/) specification. Use the interactive commit tool:

```bash
npm run commit
```

This will guide you through creating a properly formatted commit message.

### Commit Types

- **feat**: A new feature (minor version bump)
- **fix**: A bug fix (patch version bump)
- **docs**: Documentation changes (patch version bump)
- **style**: Code style changes (patch version bump)
- **refactor**: Code refactoring (patch version bump)
- **test**: Adding or updating tests (patch version bump)
- **chore**: Build process or auxiliary tool changes (patch version bump)
- **perf**: Performance improvements (patch version bump)
- **ci**: CI configuration changes (patch version bump)
- **build**: Build system changes (patch version bump)
- **revert**: Reverting previous changes (patch version bump)

### Breaking Changes

For breaking changes, include `BREAKING CHANGE:` in the body:

```bash
feat: remove deprecated hook

BREAKING CHANGE: this hook is no longer available
```

or

```bash
feat: update validation rules

BREAKING CHANGE: The validation behavior has changed and may affect existing configurations.
```

## Testing

### Manual Testing

1. **Create a test chart**:

   ```bash
   mkdir test-chart
   cd test-chart
   helm create .
   ```

2. **Test individual hooks**:

   ```bash
   ../hooks/helm-lint.sh
   ../hooks/helm-template.sh
   ../hooks/helm-unittest.sh
   ```

3. **Test with pre-commit**:

   ```bash
   cat > .pre-commit-config.yaml << 'EOF'
   repos:
     - repo: local
       hooks:
         - id: helm-lint
           name: Helm Lint
           entry: ../hooks/helm-lint.sh
           language: script
           files: '(Chart\.yaml|values\.yaml|.*\.tpl)$'
   EOF

   pre-commit run --all-files
   ```

### Automated Testing

The CI pipeline will automatically test your changes. You can run the same tests locally:

```bash
# This requires Docker and various tools to be installed
# See .github/workflows/ci.yml for the full setup
```

## Adding New Hooks

To add a new hook:

1. **Create the hook script** in `hooks/`:

   ```bash
   touch hooks/helm-newfeature.sh
   chmod +x hooks/helm-newfeature.sh
   ```

2. **Add hook definition** to `.pre-commit-hooks.yaml`:

   ```yaml
   - id: helm-newfeature
     name: Helm New Feature
     description: Description of what this hook does
     entry: hooks/helm-newfeature.sh
     language: script
     files: '(Chart\.yaml|values\.yaml|.*\.tpl)$'
     require_serial: false
     pass_filenames: false
     always_run: false
   ```

3. **Update documentation** in `README.md`:
   - Add to the features list
   - Add configuration examples
   - Add to prerequisites if needed

4. **Add tests** to the CI workflow in `.github/workflows/ci.yml`

## Hook Script Guidelines

### Script Structure

```bash
#!/bin/bash

set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HOOK_ID="helm-newfeature"

function main() {
  local -r hook_config="$*"
  local exit_code=0

  # Check if required tools are installed
  if ! command -v required-tool &> /dev/null; then
    echo "Error: required-tool is not installed or not in PATH"
    exit 1
  fi

  # Find charts
  local charts=()
  while IFS= read -r -d '' chart_file; do
    chart_dir=$(dirname "$chart_file")
    charts+=("$chart_dir")
  done < <(find . -name "Chart.yaml" -type f -print0)

  if [ ${#charts[@]} -eq 0 ]; then
    echo "No Helm charts found"
    exit 0
  fi

  # Process each chart
  for chart_dir in "${charts[@]}"; do
    echo "Processing chart: $chart_dir"

    # Your hook logic here
    if ! your-command "$chart_dir"; then
      echo "Hook failed for chart: $chart_dir"
      exit_code=1
    fi
  done

  if [ $exit_code -ne 0 ]; then
    echo "Hook failed for one or more charts"
    exit $exit_code
  fi

  echo "Hook passed for all charts"
}

main "$@"
```

### Best Practices

1. **Error handling**: Always use `set -e` and proper exit codes
2. **Tool verification**: Check if required tools are installed
3. **Chart discovery**: Use consistent chart discovery logic
4. **Dependencies**: Update dependencies before processing if needed
5. **Arguments**: Support configuration via arguments and environment variables
6. **Output**: Provide clear, actionable error messages
7. **Temporary files**: Clean up any temporary files created

## Pull Request Process

1. **Create a feature branch**:

   ```bash
   git checkout -b feat/your-feature-name
   ```

2. **Make your changes** following the guidelines above

3. **Test your changes** thoroughly

4. **Commit your changes** using conventional commits:

   ```bash
   npm run commit
   ```

5. **Push to your fork**:

   ```bash
   git push origin feat/your-feature-name
   ```

6. **Create a pull request** with:
   - Clear description of changes
   - Testing instructions
   - Breaking change notes (if applicable)

## Release Process

Releases are automated using semantic-release:

1. **Push to main**: When commits are pushed to `main`, semantic-release will:
   - Analyze commits since the last release
   - Determine the next version number
   - Generate changelog
   - Create GitHub release
   - Update CHANGELOG.md

2. **Pre-releases**: Commits to `develop` create pre-release versions

3. **Version bumps**:
   - **patch**: fix, docs, style, refactor, perf, test, build, ci, chore, revert
   - **minor**: feat
   - **major**: any commit with `BREAKING CHANGE:` in the body

## Questions or Issues?

- Open an issue for bugs or feature requests
- Start a discussion for questions or ideas
- Check existing issues before creating new ones

## Code of Conduct

Please be respectful and constructive in all interactions. We aim to create a welcoming environment for all contributors.

Thank you for contributing to pre-commit-helm!
