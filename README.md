# pre-commit-helm

A collection of Git hooks for Helm to use with the [pre-commit](https://pre-commit.com/) framework.

## Features

- **helm-lint**: Validates Helm chart syntax and best practices
- **helm-template**: Tests chart template rendering without installation
- **helm-unittest**: Runs Helm unit tests using helm-unittest plugin
- **helm-docs**: Generates/updates chart documentation
- **helm-security**: Security scanning with Trivy
- **helm-dependency-update**: Updates chart dependencies
- **helm-kubeval**: Validates Kubernetes manifests

## Installation

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
      - id: helm-kubeval
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

To trigger a major version bump, include `BREAKING CHANGE:` in the commit body or add `!` after the type:

```bash
feat!: remove support for helm v2
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
- [kubeval](https://github.com/instrumenta/kubeval) (for helm-kubeval hook)

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

### helm-kubeval

Validates Kubernetes manifests generated by Helm templates.

```yaml
- id: helm-kubeval
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
      - id: helm-kubeval
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

## Troubleshooting

### Common Issues

1. **helm-unittest not found**: Install the plugin with `helm plugin install https://github.com/helm-unittest/helm-unittest`
2. **helm-docs not found**: Install with `go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest`
3. **Trivy not found**: Install from [official docs](https://aquasecurity.github.io/trivy/latest/getting-started/installation/)

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
