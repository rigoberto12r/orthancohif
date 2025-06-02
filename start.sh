#!/bin/bash

# Orthanc + OHIF Docker Stack Startup Script
# This script initializes and starts the complete Docker stack

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check if Docker Compose is available
check_docker_compose() {
    if ! docker-compose --version >/dev/null 2>&1; then
        print_error "Docker Compose is not available. Please install Docker Compose."
        exit 1
    fi
    print_success "Docker Compose is available"
}

# Function to create necessary directories
create_directories() {
    print_status "Creating necessary directories..."
    
    directories=(
        "config"
        "config/ohif"
        "scripts"
        "nginx"
        "nginx/ssl"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_status "Created directory: $dir"
        fi
    done
    
    print_success "All directories are ready"
}

# Function to check if configuration files exist
check_config_files() {
    print_status "Checking configuration files..."
    
    required_files=(
        "config/orthanc.json"
        "config/ohif/default.js"
        "nginx/nginx.conf"
        "scripts/main.py"
        "scripts/autorouting.lua"
        "docker-compose.yml"
    )
    
    missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        print_error "Missing configuration files:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        print_error "Please ensure all configuration files are present."
        exit 1
    fi
    
    print_success "All configuration files are present"
}

# Function to pull latest Docker images
pull_images() {
    print_status "Pulling latest Docker images..."
    docker-compose pull
    print_success "Docker images updated"
}

# Function to start the services
start_services() {
    print_status "Starting Orthanc + OHIF Docker stack..."
    docker-compose up -d
    print_success "Services started successfully"
}

# Function to wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Wait for Orthanc
    print_status "Checking Orthanc availability..."
    timeout=60
    counter=0
    
    while [ $counter -lt $timeout ]; do
        if curl -s http://localhost:8042/system >/dev/null 2>&1; then
            print_success "Orthanc is ready"
            break
        fi
        
        if [ $counter -eq $timeout ]; then
            print_error "Orthanc failed to start within $timeout seconds"
            exit 1
        fi
        
        sleep 2
        counter=$((counter + 2))
        echo -n "."
    done
    
    echo ""
    
    # Wait for OHIF
    print_status "Checking OHIF availability..."
    counter=0
    
    while [ $counter -lt $timeout ]; do
        if curl -s http://localhost:3000 >/dev/null 2>&1; then
            print_success "OHIF is ready"
            break
        fi
        
        if [ $counter -eq $timeout ]; then
            print_error "OHIF failed to start within $timeout seconds"
            exit 1
        fi
        
        sleep 2
        counter=$((counter + 2))
        echo -n "."
    done
    
    echo ""
    
    # Wait for Nginx
    print_status "Checking Nginx proxy availability..."
    counter=0
    
    while [ $counter -lt $timeout ]; do
        if curl -s http://localhost >/dev/null 2>&1; then
            print_success "Nginx proxy is ready"
            break
        fi
        
        if [ $counter -eq $timeout ]; then
            print_error "Nginx proxy failed to start within $timeout seconds"
            exit 1
        fi
        
        sleep 2
        counter=$((counter + 2))
        echo -n "."
    done
    
    echo ""
}

# Function to display service status
show_status() {
    print_status "Service Status:"
    docker-compose ps
    echo ""
}

# Function to display access URLs
show_urls() {
    print_success "🎉 Orthanc + OHIF Stack is ready!"
    echo ""
    echo -e "${BLUE}📱 Access URLs:${NC}"
    echo -e "  🔍 ${GREEN}OHIF Viewer:${NC}     http://localhost"
    echo -e "  ⚙️  ${GREEN}Orthanc Explorer:${NC} http://localhost/orthanc"
    echo -e "  🌐 ${GREEN}Nginx Proxy:${NC}     http://localhost"
    echo -e "  🔧 ${GREEN}Orthanc API:${NC}     http://localhost:8042"
    echo ""
    echo -e "${BLUE}📊 Monitoring:${NC}"
    echo -e "  📈 System Status:    http://localhost:8042/system"
    echo -e "  📊 Statistics:       http://localhost:8042/statistics"
    echo -e "  🔍 Custom Status:    http://localhost:8042/custom/status"
    echo ""
    echo -e "${BLUE}📚 Logs:${NC}"
    echo -e "  View all logs:       ${YELLOW}docker-compose logs${NC}"
    echo -e "  Follow logs:         ${YELLOW}docker-compose logs -f${NC}"
    echo -e "  Orthanc logs:        ${YELLOW}docker-compose logs orthanc${NC}"
    echo ""
}

# Function to run health checks
health_check() {
    print_status "Running health checks..."
    
    # Check Orthanc system endpoint
    if curl -s http://localhost:8042/system | jq . >/dev/null 2>&1; then
        print_success "✅ Orthanc system endpoint is healthy"
    else
        print_warning "⚠️  Orthanc system endpoint check failed"
    fi
    
    # Check DICOMweb endpoint
    if curl -s http://localhost:8042/dicom-web/studies >/dev/null 2>&1; then
        print_success "✅ DICOMweb endpoint is healthy"
    else
        print_warning "⚠️  DICOMweb endpoint check failed"
    fi
    
    # Check custom Python endpoint
    if curl -s http://localhost:8042/custom/status | jq . >/dev/null 2>&1; then
        print_success "✅ Custom Python endpoints are healthy"
    else
        print_warning "⚠️  Custom Python endpoints check failed"
    fi
    
    # Check OHIF
    if curl -s http://localhost:3000 >/dev/null 2>&1; then
        print_success "✅ OHIF viewer is healthy"
    else
        print_warning "⚠️  OHIF viewer check failed"
    fi
    
    # Check Nginx proxy
    if curl -s http://localhost >/dev/null 2>&1; then
        print_success "✅ Nginx proxy is healthy"
    else
        print_warning "⚠️  Nginx proxy check failed"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}"
    echo "=============================================="
    echo "    Orthanc + OHIF Docker Stack Launcher"
    echo "=============================================="
    echo -e "${NC}"
    
    # Pre-flight checks
    check_docker
    check_docker_compose
    create_directories
    check_config_files
    
    # Start the stack
    pull_images
    start_services
    wait_for_services
    
    # Post-start verification
    show_status
    health_check
    show_urls
    
    echo -e "${GREEN}"
    echo "✅ Stack deployment completed successfully!"
    echo -e "${NC}"
    echo -e "${YELLOW}💡 Tip: Use 'docker-compose logs -f' to monitor logs in real-time${NC}"
    echo -e "${YELLOW}💡 Tip: Use 'docker-compose down' to stop all services${NC}"
    echo ""
}

# Handle script arguments
case "${1:-}" in
    "stop")
        print_status "Stopping Orthanc + OHIF Docker stack..."
        docker-compose down
        print_success "Services stopped"
        ;;
    "restart")
        print_status "Restarting Orthanc + OHIF Docker stack..."
        docker-compose restart
        wait_for_services
        health_check
        show_urls
        ;;
    "logs")
        docker-compose logs -f
        ;;
    "status")
        show_status
        health_check
        ;;
    "update")
        print_status "Updating Docker images..."
        docker-compose pull
        docker-compose up -d
        wait_for_services
        print_success "Update completed"
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (none)    Start the complete stack"
        echo "  stop      Stop all services"
        echo "  restart   Restart all services"
        echo "  logs      Follow logs in real-time"
        echo "  status    Show service status and health"
        echo "  update    Update Docker images and restart"
        echo "  help      Show this help message"
        ;;
    *)
        main
        ;;
esac 