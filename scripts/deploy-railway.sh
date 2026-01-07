#!/bin/bash
set -e

echo "🚀 Cronos POC - Railway Deployment Script"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "ℹ $1"
}

# Step 1: Check if Railway CLI is installed
print_info "Step 1: Checking Railway CLI..."
if ! command -v railway &> /dev/null; then
    print_error "Railway CLI not found!"
    echo "Install it with: npm install -g @railway/cli"
    exit 1
fi
print_success "Railway CLI installed"

# Step 2: Check if logged in
print_info "Step 2: Checking authentication..."
if ! railway whoami &> /dev/null; then
    print_warning "Not logged in to Railway"
    print_info "Opening browser for login..."
    railway login
else
    print_success "Already logged in to Railway"
fi

# Step 3: Check if project is linked
print_info "Step 3: Checking Railway project..."
if ! railway status &> /dev/null; then
    print_warning "No Railway project linked"
    print_info "Initializing new Railway project..."
    railway init
else
    print_success "Railway project already linked"
fi

# Step 4: Check if PostgreSQL is added
print_info "Step 4: Checking PostgreSQL database..."
print_warning "Please ensure PostgreSQL is added to your project:"
echo "  1. Go to Railway dashboard"
echo "  2. Click 'New' → 'Database' → 'Add PostgreSQL'"
echo ""
read -p "Press Enter once PostgreSQL is added..."

# Step 5: Set environment variables
print_info "Step 5: Configuring environment variables..."

# Read master key
if [ ! -f config/master.key ]; then
    print_error "config/master.key not found!"
    exit 1
fi
MASTER_KEY=$(cat config/master.key)
print_success "Read RAILS_MASTER_KEY from config/master.key"

# Prompt for admin credentials
print_info "Enter admin credentials for production:"
read -p "Admin Email (default: admin@cronos-poc.com): " ADMIN_EMAIL
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@cronos-poc.com}

read -sp "Admin Password: " ADMIN_PASSWORD
echo ""

if [ -z "$ADMIN_PASSWORD" ]; then
    print_error "Admin password cannot be empty!"
    exit 1
fi

# Set variables
print_info "Setting Railway environment variables..."
railway variables set RAILS_MASTER_KEY="$MASTER_KEY"
railway variables set ADMIN_EMAIL="$ADMIN_EMAIL"
railway variables set ADMIN_PASSWORD="$ADMIN_PASSWORD"
railway variables set RAILS_ENV="production"
railway variables set RAILS_SERVE_STATIC_FILES="true"
railway variables set RAILS_LOG_TO_STDOUT="true"
railway variables set RAILS_MAX_THREADS="5"
print_success "Environment variables configured"

# Step 6: Commit deployment files
print_info "Step 6: Committing deployment files..."
git add Procfile railway.json RAILWAY_DEPLOY.md scripts/deploy-railway.sh
if git diff --cached --quiet; then
    print_info "No new files to commit"
else
    git commit -m "feat: Add Railway deployment configuration and script"
    print_success "Deployment files committed"
fi

# Step 7: Deploy
print_info "Step 7: Deploying to Railway..."
print_warning "This will trigger a build and deployment..."
railway up

# Step 8: Show deployment info
echo ""
print_success "🎉 Deployment initiated!"
echo ""
print_info "Next steps:"
echo "  1. Monitor logs: railway logs --follow"
echo "  2. Check status: railway status"
echo "  3. Open app: railway open"
echo "  4. View variables: railway variables"
echo ""
print_info "Your admin credentials:"
echo "  Email: $ADMIN_EMAIL"
echo "  Password: [hidden]"
echo ""
