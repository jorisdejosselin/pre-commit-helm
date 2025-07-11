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
RUN wget https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
    && tar xf helm-v${HELM_VERSION}-linux-amd64.tar.gz \
    && mv linux-amd64/helm /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && rm -rf helm-v${HELM_VERSION}-linux-amd64.tar.gz linux-amd64

# Install helm-unittest plugin
RUN helm plugin install https://github.com/helm-unittest/helm-unittest

# Install helm-docs
RUN go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest

# Install Trivy
ARG TRIVY_VERSION=0.55.2
RUN wget -qO- https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz | tar xz \
    && mv trivy /usr/local/bin/trivy \
    && chmod +x /usr/local/bin/trivy

# Install kubeconform
ARG KUBECONFORM_VERSION=0.6.7
RUN wget https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz \
    && tar xf kubeconform-linux-amd64.tar.gz \
    && mv kubeconform /usr/local/bin/kubeconform \
    && chmod +x /usr/local/bin/kubeconform \
    && rm kubeconform-linux-amd64.tar.gz

# Install pre-commit
RUN pip3 install pre-commit --break-system-packages

# Create working directory
WORKDIR /workspace

# Copy hook scripts
COPY hooks/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# Set entrypoint to bash for interactive use
ENTRYPOINT ["/bin/bash"]
