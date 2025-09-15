# 🏗️ Multi-stage DevOps Tools Container
# Optimized for size and security

# ========================================
# Stage 1: Builder - Download and build tools
# ========================================
FROM ubuntu:22.04 AS builder

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Tool versions
ENV TERRAFORM_VERSION=1.5.0
ENV KUBECTL_VERSION=1.28.0
ENV HELM_VERSION=3.12.0
ENV YQ_VERSION=4.35.2

# Create directories for tools
RUN mkdir -p /tools/bin

# Download and extract Terraform
RUN wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /tools/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Download kubectl
RUN curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /tools/bin/

# Download and extract Helm
RUN wget -q https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
    && tar -zxf helm-v${HELM_VERSION}-linux-amd64.tar.gz \
    && mv linux-amd64/helm /tools/bin/ \
    && rm -rf helm-v${HELM_VERSION}-linux-amd64.tar.gz linux-amd64

# Download AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install --install-dir /tools/aws-cli --bin-dir /tools/bin \
    && rm -rf aws awscliv2.zip

# Download yq
RUN curl -L "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" -o /tools/bin/yq \
    && chmod +x /tools/bin/yq

# Download Docker CLI (without daemon)
RUN curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-24.0.6.tgz -o docker.tgz \
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

# Verify tools are working (as root for build)
RUN terraform version && \
    kubectl version --client && \
    helm version && \
    aws --version && \
    docker --version && \
    yq --version

# Switch to non-root user
USER devops

# Set environment variables
ENV PATH="/usr/local/bin:${PATH}"
ENV WORKSPACE="/workspace"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD terraform version && kubectl version --client && helm version

CMD ["/bin/bash"]
