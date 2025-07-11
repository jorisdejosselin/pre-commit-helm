FROM alpine:3.20

# Set labels for GitHub Container Registry
LABEL org.opencontainers.image.source="https://github.com/jorisdejosselin/pre-commit-helm"
LABEL org.opencontainers.image.description="Pre-commit hooks for Helm charts with all dependencies included"
LABEL org.opencontainers.image.licenses="MIT"

# Install system dependencies
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    git \
    go \
    python3 \
    py3-pip \
    && rm -rf /var/cache/apk/*

# Set Go environment variables
ENV GOPATH=/usr/local/go
ENV GOBIN=/usr/local/bin
ENV PATH=$PATH:$GOBIN

# Install Helm
ARG HELM_VERSION=3.14.0
ARG TARGETARCH
RUN case ${TARGETARCH} in \
        "amd64")  HELM_ARCH=amd64  ;; \
        "arm64")  HELM_ARCH=arm64  ;; \
        *)        HELM_ARCH=amd64  ;; \
    esac \
    && wget https://get.helm.sh/helm-v${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz \
    && tar xf helm-v${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz \
    && mv linux-${HELM_ARCH}/helm /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && rm -rf helm-v${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz linux-${HELM_ARCH}

# Install helm-unittest plugin globally
# First, set up a global helm plugins directory
ENV HELM_PLUGINS=/usr/local/helm/plugins
RUN mkdir -p $HELM_PLUGINS

# Install helm-unittest plugin to the global location
RUN helm plugin install https://github.com/helm-unittest/helm-unittest

# Make sure the plugin is accessible to all users
RUN chmod -R 755 /root/.local/share/helm/plugins/ 2>/dev/null || true
RUN chmod -R 755 /root/.helm/plugins/ 2>/dev/null || true
RUN chmod -R 755 $HELM_PLUGINS/ 2>/dev/null || true

# Install helm-docs
RUN go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest

# Install Trivy
ARG TRIVY_VERSION=0.55.2
RUN case ${TARGETARCH} in \
        "amd64")  TRIVY_ARCH=64bit   ;; \
        "arm64")  TRIVY_ARCH=ARM64   ;; \
        *)        TRIVY_ARCH=64bit   ;; \
    esac \
    && wget -qO- https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${TRIVY_ARCH}.tar.gz | tar xz \
    && mv trivy /usr/local/bin/trivy \
    && chmod +x /usr/local/bin/trivy

# Install kubeconform
ARG KUBECONFORM_VERSION=0.6.7
RUN case ${TARGETARCH} in \
        "amd64")  KUBE_ARCH=amd64  ;; \
        "arm64")  KUBE_ARCH=arm64  ;; \
        *)        KUBE_ARCH=amd64  ;; \
    esac \
    && wget https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-${KUBE_ARCH}.tar.gz \
    && tar xf kubeconform-linux-${KUBE_ARCH}.tar.gz \
    && mv kubeconform /usr/local/bin/kubeconform \
    && chmod +x /usr/local/bin/kubeconform \
    && rm kubeconform-linux-${KUBE_ARCH}.tar.gz

# Install pre-commit
RUN pip3 install pre-commit --break-system-packages

# Create working directory
WORKDIR /workspace

# Copy hook scripts
COPY hooks/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# Set entrypoint to bash for interactive use
ENTRYPOINT ["/bin/bash"]
