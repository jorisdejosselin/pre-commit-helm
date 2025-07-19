# pre-commit-helm

[![Tests](https://github.com/jorisdejosselin/pre-commit-helm/actions/workflows/test-hooks.yml/badge.svg)](https://github.com/jorisdejosselin/pre-commit-helm/actions/workflows/test-hooks.yml)
[![Release](https://github.com/jorisdejosselin/pre-commit-helm/actions/workflows/release.yml/badge.svg)](https://github.com/jorisdejosselin/pre-commit-helm/actions/workflows/release.yml)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/jorisdejosselin/pre-commit-helm?sort=semver&logo=github)](https://github.com/jorisdejosselin/pre-commit-helm/releases)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A collection of Git hooks for Helm to use with the [pre-commit](https://pre-commit.com/) framework.

## Features

- **helm-lint**: Validates Helm chart syntax and best practices
- **helm-template**: Tests chart template rendering without installation
- **helm-unittest**: Runs Helm unit tests using helm-unittest plugin
- **helm-docs**: Generates/updates chart documentation
- **helm-security**: Security scanning with Trivy
- **helm-dependency-update**: Updates chart dependencies
- **helm-kubeconform**: Validates Kubernetes manifests

## Installation

### Option 1: Using the Pre-built Container (Recommended)

The easiest way to use these hooks is with our pre-built container that includes all dependencies:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/jorisdejosselin/pre-commit-helm
    rev: v1.0.1  # Use the latest stable version
    hooks:
      - id: helm-lint-docker
      - id: helm-template-docker
      - id: helm-unittest-docker
      - id: helm-docs-docker
      - id: helm-security-docker
      - id: helm-dependency-update-docker
      - id: helm-kubeconform-docker
```

> **Note**: For testing pre-release features, you can use a pre-release tag like `v1.5.0-beta.1`.
> The Docker hooks will automatically use the corresponding container tag.

**Benefits:**
- ✅ No need to install Helm, trivy, kubeconform, or other dependencies
- ✅ Consistent environment across all developers
- ✅ Faster setup and execution
- ✅ Supports both AMD64 and ARM64 architectures

### Option 2: Local Installation

### 1. Install pre-commit

```bash
# Using pip
pip install pre-commit

# Using conda
conda install -c conda-forge pre-commit

# Using homebrew
brew install pre-commit
```

### 2. Add to your `.pre-commit-config.yaml`

```yaml
repos:
  - repo: https://github.com/jorisdejosselin/pre-commit-helm
    rev: v1.0.0  # Use the ref you want to point at
    hooks:
      - id: helm-lint
      - id: helm-template
      - id: helm-unittest
      - id: helm-docs
      - id: helm-security
      - id: helm-dependency-update
      - id: helm-kubeconform
```

### 3. Install the git hook scripts

```bash
pre-commit install
```

## Semantic Versioning & Releases

This project uses [semantic-release](https://semantic-release.gitbook.io/) for automated versioning and GitHub releases. Releases are automatically created when commits are pushed to the `main` branch following the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Commit Message Format

We use the [Angular Commit Message Conventions](https://github.com/angular/angular/blob/master/CONTRIBUTING.md#-commit-message-format):

```text
<type>(<scope>): <short summary>
  │       │             │
  │       │             └─⫸ Summary in present tense. Not capitalized. No period at the end.
  │       │
  │       └─⫸ Commit Scope: Optional contextual information
  │
  └─⫸ Commit Type: feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert
```

### Commit Types

- **feat**: A new feature (triggers minor version bump)
- **fix**: A bug fix (triggers patch version bump)
- **docs**: Documentation only changes (triggers patch version bump)
- **style**: Changes that do not affect the meaning of the code (triggers patch version bump)
- **refactor**: A code change that neither fixes a bug nor adds a feature (triggers patch version bump)
- **test**: Adding missing tests or correcting existing tests (triggers patch version bump)
- **chore**: Changes to the build process or auxiliary tools (triggers patch version bump)
- **perf**: A code change that improves performance (triggers patch version bump)
- **ci**: Changes to CI configuration files and scripts (triggers patch version bump)
- **build**: Changes that affect the build system or external dependencies (triggers patch version bump)
- **revert**: Reverts a previous commit (triggers patch version bump)

### Breaking Changes

To trigger a major version bump, include `BREAKING CHANGE:` in the commit body:

```bash
feat: remove support for helm v2

BREAKING CHANGE: helm v2 is no longer supported
```

or

```bash
feat: add new validation rules

BREAKING CHANGE: The validation rules have been updated and may cause existing charts to fail validation.
```

### Development Workflow

1. **Making commits**: Use `npm run commit` to create properly formatted commit messages:

   ```bash
   npm install  # Install dependencies
   npm run commit  # Interactive commit tool
   ```

2. **Automatic releases**: When you push to `main`, GitHub Actions will:
   - Analyze commits since the last release
   - Generate a changelog
   - Create a new release with semantic version
   - Update the CHANGELOG.md file

3. **Pre-release versions**: Commits to `develop` branch will create pre-release versions (e.g., `v1.2.0-beta.1`)

### Available Versions

You can always use the latest release by specifying:

```yaml
repos:
  - repo: https://github.com/jorisdejosselin/pre-commit-helm
    rev: v1.0.0  # or use a specific version like v1.2.3
```

Or use the latest main branch (not recommended for production):

```yaml
repos:
  - repo: https://github.com/jorisdejosselin/pre-commit-helm
    rev: main
```

## Prerequisites

Make sure you have the following tools installed:

- [Helm](https://helm.sh/docs/intro/install/) >= 3.0.0
- [helm-unittest](https://github.com/helm-unittest/helm-unittest) plugin (for helm-unittest hook)
- [helm-docs](https://github.com/norwoodj/helm-docs) (for helm-docs hook)
- [Trivy](https://aquasecurity.github.io/trivy/) (for helm-security hook)
- [kubeconform](https://github.com/yannh/kubeconform) (for helm-kubeconform hook)

## Hook Configuration

### helm-lint

Runs `helm lint` on your Helm charts to validate syntax and best practices.

```yaml
- id: helm-lint
  args: ['--strict']  # Optional: fail on warnings
```

### helm-template

Renders chart templates to validate they generate valid Kubernetes manifests.

```yaml
- id: helm-template
  args: ['--debug']  # Optional: show debug output
```

### helm-unittest

Runs unit tests for your Helm charts using the helm-unittest plugin.

```yaml
- id: helm-unittest
  args: ['--color', '--output-type', 'JUnit']
```

### helm-docs

Generates documentation for your Helm charts.

```yaml
- id: helm-docs
  args: ['--sort-values-order', 'file']
```

### helm-security

Scans your Helm charts for security vulnerabilities using Trivy.

```yaml
- id: helm-security
  args: ['--severity', 'HIGH,CRITICAL']
```

### helm-dependency-update

Updates chart dependencies when Chart.yaml changes.

```yaml
- id: helm-dependency-update
  args: ['--skip-refresh']  # Optional: skip repository refresh
```

### helm-kubeconform

Validates Kubernetes manifests generated by Helm templates using kubeconform.

```yaml
- id: helm-kubeconform
  args: ['--kubernetes-version', '1.28.0']
```

## Usage Examples

### Basic Configuration

```yaml
repos:
  - repo: https://github.com/jorisdejosselin/pre-commit-helm
    rev: v1.0.0
    hooks:
      - id: helm-lint
      - id: helm-template
```

### Advanced Configuration

```yaml
repos:
  - repo: https://github.com/jorisdejosselin/pre-commit-helm
    rev: v1.0.0
    hooks:
      - id: helm-lint
        args: ['--strict']
      - id: helm-template
        args: ['--debug']
      - id: helm-unittest
        args: ['--color']
      - id: helm-docs
      - id: helm-security
        args: ['--severity', 'HIGH,CRITICAL']
      - id: helm-dependency-update
      - id: helm-kubeconform
        args: ['--kubernetes-version', '1.28.0']
```

## Chart Structure

This tool works best with charts following the standard Helm structure:

```text
mychart/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ...
├── tests/
│   └── *_test.yaml
└── README.md
```

## Using the Container Directly

You can also use the container directly for testing or CI/CD:

```bash
# Pull the stable container
docker pull ghcr.io/jorisdejosselin/pre-commit-helm:stable

# Or pull a specific version
docker pull ghcr.io/jorisdejosselin/pre-commit-helm:v1.5.0

# Or pull the latest pre-release for testing
docker pull ghcr.io/jorisdejosselin/pre-commit-helm:develop

# Run hooks directly
docker run --rm -v $(pwd):/workspace ghcr.io/jorisdejosselin/pre-commit-helm:stable \
  -c "cd /workspace && /usr/local/bin/helm-lint.sh"

# Interactive shell with all tools available
docker run -it --rm -v $(pwd):/workspace ghcr.io/jorisdejosselin/pre-commit-helm:stable

# Using docker-compose for development
docker-compose up -d
docker-compose exec pre-commit-helm bash
```

### Available Container Tags

**Stable Releases:**
- `stable`/`latest` - Latest stable release (recommended for production)
- `v1.2.3` - Specific stable version tags (e.g., `v1.5.0`, `v2.0.0`)
- `v1.2` - Major.minor version tags (automatically updated for stable releases)
- `v1` - Major version tags (automatically updated for stable releases)

**Pre-releases:**
- `develop` - Latest pre-release version (recommended for testing new features)
- `v1.2.3-beta.1` - Specific pre-release version tags (e.g., `v1.5.0-beta.1`)

**Development:**
- `main`/`develop` - Latest commit from respective branches (for CI/testing)
- `sha-abc123` - Specific commit builds

## Troubleshooting

### Common Issues

1. **helm-unittest not found**: Install the plugin with `helm plugin install https://github.com/helm-unittest/helm-unittest`
2. **helm-docs not found**: Install with `go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest`
3. **Trivy not found**: Install from [official docs](https://aquasecurity.github.io/trivy/latest/getting-started/installation/)
4. **kubeconform not found**: Install from [GitHub releases](https://github.com/yannh/kubeconform/releases)

### Environment Variables

You can configure tool behavior using environment variables:

- `HELM_LINT_STRICT`: Set to `true` to enable strict mode for helm-lint
- `HELM_TEMPLATE_DEBUG`: Set to `true` to enable debug output for helm-template
- `TRIVY_SEVERITY`: Set severity levels for security scanning (default: HIGH,CRITICAL)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

Inspired by [pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform) by Anton Babenko.
