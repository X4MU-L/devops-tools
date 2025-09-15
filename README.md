# DevOps Tools Container 🏗️

A production-ready, security-focused container with essential DevOps tools for CI/CD pipelines.

## 🚀 Quick Start

```yaml
# GitHub Actions
jobs:
  deploy:
    runs-on: ubuntu-latest
    container: ghcr.io/your-org/devops-tools:latest-ubuntu
    steps:
      - uses: actions/checkout@v4
      - run: terraform version && kubectl version --client
```

## 📦 Available Images

### Ubuntu-based (Recommended)
```bash
docker pull ghcr.io/your-org/devops-tools:latest-ubuntu
```
- **Size**: ~200MB
- **Base**: Ubuntu 22.04 LTS
- **Use case**: Production workloads, full compatibility

### Alpine-based (Lightweight)
```bash
docker pull ghcr.io/your-org/devops-tools:latest-alpine
```
- **Size**: ~150MB  
- **Base**: Alpine 3.18
- **Use case**: Speed-critical scenarios, smaller footprint

## 🛠️ Included Tools

| Tool | Version | Purpose |
|------|---------|---------|
| **Terraform** | 1.5.0 | Infrastructure as Code |
| **kubectl** | 1.28.0 | Kubernetes CLI |
| **Helm** | 3.12.0 | Kubernetes package manager |
| **AWS CLI** | v2 | AWS operations |
| **Docker CLI** | 24.0.6 | Container operations |
| **yq** | 4.35.2 | YAML processor |
| **Git** | Latest | Version control |
| **curl/wget** | Latest | HTTP clients |
| **jq** | Latest | JSON processor |

## 🏷️ Tagging Strategy

| Tag Pattern | Description | Example |
|-------------|-------------|---------|
| `latest-ubuntu` | Latest Ubuntu build | `ghcr.io/your-org/devops-tools:latest-ubuntu` |
| `latest-alpine` | Latest Alpine build | `ghcr.io/your-org/devops-tools:latest-alpine` |
| `v1.2.3-ubuntu` | Semantic version Ubuntu | `ghcr.io/your-org/devops-tools:v1.2.3-ubuntu` |
| `v1.2.3-alpine` | Semantic version Alpine | `ghcr.io/your-org/devops-tools:v1.2.3-alpine` |
| `main-abc123-ubuntu` | Branch + commit SHA | `ghcr.io/your-org/devops-tools:main-abc123-ubuntu` |

## 🔧 Usage Examples

### Local Development
```bash
# Run interactive shell
docker run -it --rm ghcr.io/your-org/devops-tools:latest-ubuntu

# Mount current directory
docker run -it --rm -v $(pwd):/workspace ghcr.io/your-org/devops-tools:latest-ubuntu

# Run specific command
docker run --rm ghcr.io/your-org/devops-tools:latest-ubuntu terraform version
```

### GitHub Actions
```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/your-org/devops-tools:v1.0.0-ubuntu
      options: --user root  # If needed for GitHub Actions
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
        aws-region: us-east-1
    
    - name: Deploy with Terraform
      run: |
        cd terraform
        terraform init
        terraform plan
        terraform apply -auto-approve
    
    - name: Deploy with Helm
      run: |
        aws eks update-kubeconfig --name my-cluster
        helm upgrade --install myapp ./helm/myapp
```

### GitLab CI
```yaml
image: ghcr.io/your-org/devops-tools:latest-ubuntu

stages:
  - deploy

deploy:
  stage: deploy
  script:
    - terraform --version
    - kubectl version --client
    - helm version
```

### Jenkins Pipeline
```groovy
pipeline {
    agent {
        docker { 
            image 'ghcr.io/your-org/devops-tools:latest-ubuntu'
            args '-u root:root'
        }
    }
    stages {
        stage('Deploy') {
            steps {
                sh 'terraform version'
                sh 'kubectl version --client'
            }
        }
    }
}
```

## 🔒 Security Features

- **Multi-stage builds** for minimal attack surface
- **Non-root user** (`devops:1000`) for runtime
- **Vulnerability scanning** with Trivy
- **Regular security updates** via scheduled builds
- **Minimal dependencies** - only essential packages
- **Health checks** for container monitoring

## 🚀 Performance Optimizations

- **Layer caching** with GitHub Actions cache
- **Multi-platform builds** (AMD64, ARM64)
- **Optimized layer ordering** for better caching
- **Minimal base images** for faster pulls
- **Build cache** optimization

## 🔄 Automated Updates

The container is automatically rebuilt:
- **Weekly** - Every Monday at 2 AM UTC for security updates
- **On push** - When code changes are pushed
- **On tags** - When new versions are tagged
- **On PR** - For testing changes

## 📋 Environment Setup Requirements

### GitHub Repository Secrets
No additional secrets required! Uses `GITHUB_TOKEN` for GitHub Container Registry.

### Repository Settings
1. **Packages**: Enable GitHub Container Registry
2. **Actions**: Enable GitHub Actions
3. **Security**: Enable Dependabot alerts

### Optional Secrets (for enhanced features)
```bash
# For Slack notifications (optional)
SLACK_WEBHOOK_URL=https://hooks.slack.com/...

# For Docker Hub (alternative registry)
DOCKERHUB_USERNAME=your-username
DOCKERHUB_TOKEN=your-token
```

## 🏗️ Building Locally

```bash
# Clone repository
git clone https://github.com/your-org/devops-tools.git
cd devops-tools

# Build Ubuntu variant
docker build -t devops-tools:ubuntu .

# Build Alpine variant  
docker build -t devops-tools:alpine -f Dockerfile.alpine .

# Test functionality
docker run --rm devops-tools:ubuntu terraform version
```

## 📊 Image Comparison

| Metric | Ubuntu | Alpine |
|--------|--------|---------|
| **Base Image** | Ubuntu 22.04 | Alpine 3.18 |
| **Size** | ~200MB | ~150MB |
| **Security Updates** | More frequent | Less frequent |
| **Compatibility** | Higher | Good |
| **Performance** | Standard | Faster startup |
| **Use Case** | Production | Speed-critical |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Create a pull request

## 📝 Version History

### v1.0.0
- Initial release
- Terraform 1.5.0
- kubectl 1.28.0
- Helm 3.12.0
- Multi-stage builds
- Security hardening

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/your-org/devops-tools/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/devops-tools/discussions)
- **Security**: Report to security@your-org.com
