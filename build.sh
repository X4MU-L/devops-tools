#!/bin/bash

# 🏗️ Local Build Script for DevOps Tools Container
# Usage: ./build.sh [variant] [tag]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Helper functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Configuration
REGISTRY=${REGISTRY:-"ghcr.io/your-org"}
IMAGE_NAME=${IMAGE_NAME:-"devops-tools"}
VARIANT=${1:-"ubuntu"}
TAG=${2:-"local"}

# Dockerfile selection
if [ "$VARIANT" = "ubuntu" ]; then
    DOCKERFILE="Dockerfile"
elif [ "$VARIANT" = "alpine" ]; then
    DOCKERFILE="Dockerfile.alpine"
else
    log_error "Invalid variant: $VARIANT. Use 'ubuntu' or 'alpine'"
    exit 1
fi

# Build configuration
FULL_TAG="$REGISTRY/$IMAGE_NAME:$TAG-$VARIANT"
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

log_info "🏗️  Building DevOps Tools Container"
log_info "Variant: $VARIANT"
log_info "Tag: $FULL_TAG"
log_info "Dockerfile: $DOCKERFILE"

# Build the image
log_info "Building image..."
docker build \
    --file "$DOCKERFILE" \
    --tag "$FULL_TAG" \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg VCS_REF="$VCS_REF" \
    --build-arg VERSION="$TAG" \
    .

log_success "Image built successfully: $FULL_TAG"

# Test the image
log_info "Testing image functionality..."
docker run --rm "$FULL_TAG" bash -c "
    echo '🧪 Testing tools...'
    terraform version || exit 1
    kubectl version --client || exit 1
    helm version || exit 1
    aws --version || exit 1
    yq --version || exit 1
    echo '✅ All tools working!'
"

# Show image info
log_info "Image information:"
docker images | grep "$IMAGE_NAME" | grep "$TAG-$VARIANT"

# Size comparison
SIZE=$(docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep "$FULL_TAG" | awk '{print $2}')
log_success "Final image size: $SIZE"

log_success "🎉 Build completed successfully!"
log_info "Run with: docker run -it --rm $FULL_TAG"

# Optional: Tag as latest for this variant
read -p "Tag as latest-$VARIANT? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    LATEST_TAG="$REGISTRY/$IMAGE_NAME:latest-$VARIANT"
    docker tag "$FULL_TAG" "$LATEST_TAG"
    log_success "Tagged as: $LATEST_TAG"
fi
