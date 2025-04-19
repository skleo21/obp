# Script to deploy OBP API from GHCR to local Minikube

# Set default values
NAMESPACE=${1:-"obp-dev"}
GITHUB_USERNAME=${2:-$(git config user.name)}
TAG=${3:-"latest"}

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if GITHUB_USERNAME is provided or can be determined
if [ -z "$GITHUB_USERNAME" ]; then
    echo -e "${YELLOW}Warning: Could not determine GitHub username from git config.${NC}"
    echo "Please provide your GitHub username as the second argument:"
    echo "  ./deploy_from_ghcr.sh $NAMESPACE YOUR_GITHUB_USERNAME $TAG"
    exit 1
fi

IMAGE="ghcr.io/$GITHUB_USERNAME/obp-api:$TAG"

echo -e "${GREEN}===== Deploying OBP API from GHCR to Minikube =====${NC}"
echo "Namespace: $NAMESPACE"
echo "Image: $IMAGE"
echo -e "${GREEN}================================================${NC}"

# Check if minikube is running
if ! minikube status &>/dev/null; then
    echo -e "${YELLOW}Minikube is not running. Starting Minikube...${NC}"
    minikube start || { echo "Failed to start Minikube. Please start it manually."; exit 1; }
fi

# Create namespace
echo "Creating namespace ${NAMESPACE}..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Apply storage resources
echo "Creating storage resources..."
kubectl apply -f ../k8s/storage.yaml -n ${NAMESPACE}

# Create database credentials
echo "Creating database credentials..."
kubectl create secret generic obp-db-credentials \
  --from-literal=username=obp \
  --from-literal=password=obpsecurepassword \
  -n ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Deploy database
echo "Deploying database..."
kubectl apply -f ../k8s/database.yaml -n ${NAMESPACE}

# Create a temporary copy of the deployment file
echo "Preparing deployment manifest..."
cp ../k8s/obp-api.yaml /tmp/obp-api-modified.yaml

# Update image in deployment file
echo "Updating image to: $IMAGE"
sed -i.bak "s|\${REGISTRY}/obp-api:\${TAG}|$IMAGE|g" /tmp/obp-api-modified.yaml

# Add imagePullSecrets if needed (assuming we might need to pull from private repo)
if ! kubectl get secret ghcr-auth -n ${NAMESPACE} &>/dev/null; then
    echo "Creating Docker registry secret for GHCR..."
    
    # Ask for GitHub Personal Access Token if needed
    if [ -z "$GITHUB_TOKEN" ]; then
        echo -e "${YELLOW}GitHub Personal Access Token not found in environment.${NC}"
        echo "You can create one at: https://github.com/settings/tokens"
        echo "Token needs 'read:packages' scope."
        echo "Enter your GitHub Personal Access Token (input will be hidden):"
        read -s GITHUB_TOKEN
        echo
    fi
    
    # Create the pull secret
    kubectl create secret docker-registry ghcr-auth \
        --docker-server=ghcr.io \
        --docker-username="$GITHUB_USERNAME" \
        --docker-password="$GITHUB_TOKEN" \
        -n ${NAMESPACE}
        
    # Add imagePullSecrets to the service account
    kubectl patch serviceaccount default -n ${NAMESPACE} -p '{"imagePullSecrets": [{"name": "ghcr-auth"}]}'
fi

# Apply the updated deployment
echo "Deploying OBP API..."
kubectl apply -f /tmp/obp-api-modified.yaml -n ${NAMESPACE}

# Clean up the temporary file
rm /tmp/obp-api-modified.yaml /tmp/obp-api-modified.yaml.bak

# Deploy ingress
echo "Deploying ingress..."
kubectl apply -f ../k8s/ingress.yaml -n ${NAMESPACE}

# Wait for deployments to be ready
echo "Waiting for deployments to be ready..."
kubectl rollout status deployment/obp-db -n ${NAMESPACE}
kubectl rollout status deployment/obp-api -n ${NAMESPACE}

# Check if host entry exists in /etc/hosts
if ! grep -q "obp.local" /etc/hosts; then
    MINIKUBE_IP=$(minikube ip)
    echo -e "${YELLOW}Warning: obp.local not found in /etc/hosts${NC}"
    echo "To access the application, add this entry to your /etc/hosts file:"
    echo "  $MINIKUBE_IP obp.local"
    echo -e "${YELLOW}You can do this by running:${NC}"
    echo "  echo \"$MINIKUBE_IP obp.local\" | sudo tee -a /etc/hosts"
fi

echo -e "${GREEN}===== Deployment Complete =====${NC}"
echo "Access your application at: http://obp.local"
echo "To view pods: kubectl get pods -n $NAMESPACE"
echo "To view logs: kubectl logs -f deployment/obp-api -n $NAMESPACE"