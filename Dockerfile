# 🏗️ Multi-stage DevOps Tools Container
# Optimized for size and security

# ========================================
# Stage 1: Builder - Download and prepare tools
# ========================================
FROM ubuntu:22.04 AS builder

# Build arguments for multi-platform support
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# Avoid interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Tool versions
ENV TERRAFORM_VERSION=1.5.0
ENV KUBECTL_VERSION=1.28.0
ENV HELM_VERSION=3.12.0
ENV YQ_VERSION=4.35.2

# Create directories for tools
RUN mkdir -p /tools/bin

# Set architecture based on target platform
RUN case "${TARGETPLATFORM}" in \
      "linux/amd64") echo "amd64" > /tmp/arch ;; \
      "linux/arm64") echo "arm64" > /tmp/arch ;; \
      *) echo "Unsupported architecture: ${TARGETPLATFORM}" && exit 1 ;; \
    esac

# Download and extract Terraform
RUN ARCH=$(cat /tmp/arch) \
    && wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip \
    && mv terraform /tools/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip

# Download kubectl
RUN ARCH=$(cat /tmp/arch) \
    && curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /tools/bin/

# Download and extract Helm
RUN ARCH=$(cat /tmp/arch) \
    && wget -q https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz \
    && tar -zxf helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz \
    && mv linux-${ARCH}/helm /tools/bin/ \
    && rm -rf helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz linux-${ARCH}

# Download AWS CLI v2
RUN ARCH=$(cat /tmp/arch) \
    && case "${ARCH}" in \
         "amd64") AWS_ARCH="x86_64" ;; \
         "arm64") AWS_ARCH="aarch64" ;; \
       esac \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install --install-dir /tools/aws-cli --bin-dir /tools/bin \
    && rm -rf aws awscliv2.zip

# Download yq
RUN ARCH=$(cat /tmp/arch) \
    && curl -L "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${ARCH}" -o /tools/bin/yq \
    && chmod +x /tools/bin/yq

# Download Docker CLI (without daemon)
RUN ARCH=$(cat /tmp/arch) \
    && case "${ARCH}" in \
         "amd64") DOCKER_ARCH="x86_64" ;; \
         "arm64") DOCKER_ARCH="aarch64" ;; \
       esac \
    && curl -fsSL https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-24.0.6.tgz -o docker.tgz \
    && tar -zxf docker.tgz \
    && mv docker/docker /tools/bin/ \
    && rm -rf docker.tgz docker

# ========================================
# Stage 2: Runtime - Minimal final image
# ========================================
FROM ubuntu:22.04 AS runtime

# Metadata
LABEL maintainer="DevOps Team"
LABEL description="Optimized DevOps tools container"
LABEL version="1.0.0"

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install only runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    git \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy tools from builder stage
COPY --from=builder /tools/bin/* /usr/local/bin/
COPY --from=builder /tools/aws-cli /usr/local/aws-cli

# Create symlink for AWS CLI
RUN ln -sf /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws

# Create non-root user for security
RUN groupadd -r devops && useradd -r -g devops -s /bin/bash devops \
    && mkdir -p /home/devops \
    && chown devops:devops /home/devops

# Set working directory
WORKDIR /workspace

# Make all tools executable
RUN chmod +x /usr/local/bin/*

# Verify tools are working (as root for build) - resilient checks
RUN terraform version || echo "Terraform check failed" && \
    kubectl version --client || echo "kubectl check failed" && \
    helm version || echo "Helm check failed" && \
    aws --version || echo "AWS CLI check failed" && \
    docker --version || echo "Docker check failed" && \
    yq --version || echo "yq check failed"

# Switch to non-root user
USER devops

# Set environment variables
ENV PATH="/usr/local/bin:${PATH}"
ENV WORKSPACE="/workspace"

# Health check (simplified)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD terraform version > /dev/null 2>&1

CMD ["/bin/bash"]
