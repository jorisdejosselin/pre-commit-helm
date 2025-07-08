#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 Testing pre-commit-helm hooks...${NC}"

# Test directory
TEST_DIR="$(pwd)/test-helm-repo"
export PATH="$HOME/bin:$PATH"

cd "$TEST_DIR"

echo -e "${YELLOW}📋 Testing all hooks together...${NC}"
if pre-commit run --all-files; then
    echo -e "${GREEN}✅ All hooks passed together${NC}"
else
    echo -e "${RED}❌ Some hooks failed${NC}"
    exit 1
fi

echo -e "${YELLOW}🔍 Testing individual hooks...${NC}"

# Test each hook individually
hooks=("helm-lint" "helm-template" "helm-unittest" "helm-docs" "helm-kubeval" "helm-security")

for hook in "${hooks[@]}"; do
    echo -e "${YELLOW}Testing $hook...${NC}"
    if pre-commit run "$hook" --all-files; then
        echo -e "${GREEN}✅ $hook passed${NC}"
    else
        echo -e "${RED}❌ $hook failed${NC}"
        exit 1
    fi
done

echo -e "${YELLOW}📝 Testing git commit with hooks...${NC}"
# Create a test change
echo "# Test change 2" >> values.yaml
git add .

if git commit -m "test: add another comment to values.yaml"; then
    echo -e "${GREEN}✅ Git commit with hooks passed${NC}"
else
    echo -e "${RED}❌ Git commit with hooks failed${NC}"
    exit 1
fi

echo -e "${YELLOW}🚫 Testing failure scenarios...${NC}"

# Test security failure
echo -e "${YELLOW}Testing security scanner with insecure configuration...${NC}"
cat > templates/insecure-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: insecure-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: insecure
  template:
    metadata:
      labels:
        app: insecure
    spec:
      containers:
      - name: insecure-container
        image: "nginx:latest"
        securityContext:
          runAsUser: 0
          allowPrivilegeEscalation: true
          capabilities:
            add:
              - SYS_ADMIN
EOF

if pre-commit run helm-security --all-files; then
    echo -e "${RED}❌ Security scanner should have failed but passed${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Security scanner correctly detected insecure configuration${NC}"
fi

# Clean up insecure file
rm templates/insecure-deployment.yaml

# Test unit test failure
echo -e "${YELLOW}Testing unit test failure...${NC}"
sed -i '' 's/value: 1/value: 2/' tests/deployment_test.yaml

if pre-commit run helm-unittest --all-files; then
    echo -e "${RED}❌ Unit test should have failed but passed${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Unit test correctly detected test failure${NC}"
fi

# Fix unit test
sed -i '' 's/value: 2/value: 1/' tests/deployment_test.yaml

# Test invalid YAML
echo -e "${YELLOW}Testing invalid YAML...${NC}"
echo "invalid: yaml: content:" >> Chart.yaml

if pre-commit run helm-lint --all-files; then
    echo -e "${RED}❌ Lint should have failed but passed${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Lint correctly detected invalid YAML${NC}"
fi

# Fix Chart.yaml
git checkout Chart.yaml

echo -e "${GREEN}🎉 All pre-commit tests passed successfully!${NC}"
echo -e "${GREEN}✅ Hooks are working correctly${NC}"
echo -e "${GREEN}✅ Security scanning is functional${NC}"
echo -e "${GREEN}✅ Unit testing is functional${NC}"
echo -e "${GREEN}✅ Linting is functional${NC}"
echo -e "${GREEN}✅ Template validation is functional${NC}"
echo -e "${GREEN}✅ Kubeval is functional${NC}"
echo -e "${GREEN}✅ Documentation generation is functional${NC}"
