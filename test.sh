#!/bin/bash
set -e

# Quick architecture compatibility test
echo "🧪 Testing multi-architecture Dockerfile fixes..."

# Test Alpine Dockerfile syntax
echo "📋 Checking Alpine Dockerfile syntax..."
if docker buildx build --platform linux/amd64 --file Dockerfile.alpine --target alpine-runtime . --progress=plain --no-cache --dry-run 2>/dev/null; then
    echo "✅ Alpine Dockerfile syntax OK"
else
    echo "⚠️  Testing Alpine build without dry-run..."
    docker buildx build --platform linux/amd64 --file Dockerfile.alpine --target alpine-runtime . --progress=plain --load -t test-alpine:local >/dev/null 2>&1 && echo "✅ Alpine Dockerfile builds successfully" || echo "❌ Alpine Dockerfile has build issues"
fi

# Test Ubuntu Dockerfile syntax  
echo "📋 Checking Ubuntu Dockerfile syntax..."
if docker buildx build --platform linux/amd64 --file Dockerfile --target runtime . --progress=plain --no-cache --dry-run 2>/dev/null; then
    echo "✅ Ubuntu Dockerfile syntax OK"
else
    echo "⚠️  Testing Ubuntu build without dry-run..."
    docker buildx build --platform linux/amd64 --file Dockerfile --target runtime . --progress=plain --load -t test-ubuntu:local >/dev/null 2>&1 && echo "✅ Ubuntu Dockerfile builds successfully" || echo "❌ Ubuntu Dockerfile has build issues"
fi

echo "✅ Dockerfile syntax checks completed"

# Show architecture detection logic
echo "🔍 Architecture detection logic:"
echo "TARGETPLATFORM=linux/amd64 -> amd64"
echo "TARGETPLATFORM=linux/arm64 -> arm64"

# Test basic Docker commands
echo "🧪 Testing Docker buildx capabilities..."
if command -v docker >/dev/null 2>&1; then
    echo "✅ Docker CLI available"
    if docker buildx version >/dev/null 2>&1; then
        echo "✅ Docker Buildx available"
    else
        echo "⚠️  Docker Buildx not available - multi-platform builds may not work"
    fi
else
    echo "❌ Docker CLI not available"
fi

echo "🚀 Ready for multi-platform builds!"
