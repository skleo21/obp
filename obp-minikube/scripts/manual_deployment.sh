# scripts/manual_deployment.sh

# Set variables
NAMESPACE="obp-manual"
REGISTRY="your-registry.example.com"
TAG="latest"

# Create namespace
echo "Creating namespace ${NAMESPACE}..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Apply storage resources
echo "Creating storage resources..."
kubectl apply -f k8s/storage.yaml -n ${NAMESPACE}

# Create database credentials
echo "Creating database credentials..."
kubectl create secret generic obp-db-credentials \
  --from-literal=username=obp \
  --from-literal=password=obpsecurepassword \
  -n ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Deploy database
echo "Deploying database..."
kubectl apply -f k8s/database.yaml -n ${NAMESPACE}

# Build and push OBP API image
echo "Building OBP API docker image..."
cd docker
docker build -t ${REGISTRY}/obp-api:${TAG} .
docker push ${REGISTRY}/obp-api:${TAG}
cd ..

# Update and deploy OBP API
echo "Deploying OBP API..."
sed -i "s/\${REGISTRY}/${REGISTRY}/g" k8s/obp-api.yaml
sed -i "s/\${TAG}/${TAG}/g" k8s/obp-api.yaml
kubectl apply -f k8s/obp-api.yaml -n ${NAMESPACE}

# Deploy ingress
echo "Deploying ingress..."
kubectl apply -f k8s/ingress.yaml -n ${NAMESPACE}

# Wait for deployments to be ready
echo "Waiting for deployments to be ready..."
kubectl rollout status deployment/obp-db -n ${NAMESPACE}
kubectl rollout status deployment/obp-api -n ${NAMESPACE}

echo "Manual deployment completed successfully!"
echo "Access your application at: http://obp.local"