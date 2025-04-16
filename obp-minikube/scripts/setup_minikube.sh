# scripts/setup_minikube.sh

# Set variables
MINIKUBE_MEMORY=${MINIKUBE_MEMORY:-4096}
MINIKUBE_CPUS=${MINIKUBE_CPUS:-2}

# Check if minikube is installed
if ! command -v minikube &> /dev/null; then
    echo "Minikube is not installed. Please install it first."
    exit 1
fi

# Start minikube with required resources
echo "Starting minikube with ${MINIKUBE_MEMORY}MB memory and ${MINIKUBE_CPUS} CPUs..."
minikube start --memory ${MINIKUBE_MEMORY} --cpus ${MINIKUBE_CPUS}

# Enable required addons
echo "Enabling required minikube addons..."
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard

# Set docker environment to use minikube's docker daemon
echo "Setting up docker environment..."
eval $(minikube docker-env)
echo "You can now build docker images directly in minikube's docker daemon"

# Print useful information
echo "Minikube is ready!"
echo "Dashboard URL: $(minikube dashboard --url)"
echo "IP address: $(minikube ip)"

echo "Add the following entry to your /etc/hosts file:"
echo "$(minikube ip) obp.local"

echo "To access your application, visit: http://obp.local"