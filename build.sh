#!/bin/bash

DOMAIN_NAME="testdomain.local"

# Create self signed certificate
if [ -f "/etc/ssl/$DOMAIN_NAME.crt" ] && [ -f "/etc/ssl/$DOMAIN_NAME.key" ]; then
    echo "Self signed certificate exists."
else
    echo "Generating self-signed certificate..."
    if [ -d "/tmp/self-signed-ca/" ]; then
        rm -r /tmp/self-signed-ca/
    else
        bash self-signed-ca.sh "$DOMAIN_NAME"
        bash add-root-ca.sh # Adding the root ca to the OS and Firefox (works on Linux only)
    fi
fi

# Create nginx image and container
image_name="custom-nginx"
image_ids=($(docker images -q $image_name))
container_name="nginx-container"

echo "Creating nginx container..."

# Check if the Docker container exists
if docker ps -a --format '{{.Names}}' | grep -q "^$container_name$"; then
    echo "Docker container $container_name exists. Deleting..."
    docker stop "$container_name" && docker rm "$container_name"
    echo "Docker container $container_name deleted."
fi

if [ ${#image_ids[@]} -gt 0 ]; then
    for image_id in "${image_ids[@]}"; do
        echo "Nginx Docker image $image_id exists. Deleting..."
        docker rmi "$image_id"
        echo "Docker image $image_id deleted."
    done
fi

# Get the available port
port_number=""
start_port=8080
end_port=8090

for ((port = start_port; port <= end_port; port++)); do
    if ! [[ $(netstat -tuln | grep -E ":$port\b") ]]; then
        port_number=$port
        break
    fi
done

# Configure the available port with nginx
sed -i "s/listen 80/listen $port_number/g" "nginx.conf"

# Build and run the nginx container
docker build -t "$image_name" .
docker run -d -p $port_number:80 --name "$container_name" "$image_name"

echo "Nginx container is running on port $port_number"
