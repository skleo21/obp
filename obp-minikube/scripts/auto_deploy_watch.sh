# Script to watch for new images in GHCR and automatically deploy them

GITHUB_USERNAME=${1:-$(git config user.name)}
NAMESPACE=${2:-"obp-dev"}
CHECK_INTERVAL=${3:-300} # Default: check every 5 minutes

# Check if GITHUB_USERNAME is provided
if [ -z "$GITHUB_USERNAME" ]; then
    echo "Error: Could not determine GitHub username"
    echo "Usage: $0 GITHUB_USERNAME [NAMESPACE] [CHECK_INTERVAL]"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required for this script"
    echo "Please install it with: brew install jq (macOS) or apt-get install jq (Debian/Ubuntu)"
    exit 1
fi

echo "Starting automatic deployment watcher for ghcr.io/$GITHUB_USERNAME/obp-api"
echo "Namespace: $NAMESPACE"
echo "Check interval: $CHECK_INTERVAL seconds"

# GitHub API URL for checking packages
PACKAGES_URL="https://api.github.com/user/packages/container/obp-api/versions"

# Initialize with empty value to force first deployment
LAST_DEPLOYED_SHA=""

while true; do
    echo "Checking for new images..."
    
    # Get GitHub token from environment or prompt
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "GitHub token not found in environment"
        echo "Enter your GitHub Personal Access Token (input will be hidden):"
        read -s GITHUB_TOKEN
        echo
    fi
    
    # Get the latest SHA tag using GitHub API
    LATEST_SHA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" $PACKAGES_URL | jq -r '.[0].metadata.container.tags[] | select(. != "latest")' | head -1)
    
    if [ -z "$LATEST_SHA" ] || [ "$LATEST_SHA" == "null" ]; then
        echo "Could not retrieve latest image SHA. Waiting for next check..."
    else
        echo "Latest image SHA: $LATEST_SHA"
        
        # Deploy if this is a new SHA
        if [ "$LATEST_SHA" != "$LAST_DEPLOYED_SHA" ]; then
            echo "New image detected. Deploying..."
            ./deploy_from_ghcr.sh "$NAMESPACE" "$GITHUB_USERNAME" "$LATEST_SHA"
            LAST_DEPLOYED_SHA="$LATEST_SHA"
            echo "Deployment complete. Now watching for new images..."
        else
            echo "No new images. Already deployed: $LATEST_SHA"
        fi
    fi
    
    echo "Waiting $CHECK_INTERVAL seconds until next check..."
    sleep $CHECK_INTERVAL
done