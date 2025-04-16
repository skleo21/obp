# docker/Dockerfile
FROM openjdk:11-jre-slim

WORKDIR /opt/obp

# Install dependencies
RUN apt-get update && apt-get install -y wget curl jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set OBP version
ARG OBP_VERSION=4.0.0

# Download OBP API
RUN wget https://github.com/OpenBankProject/OBP-API/releases/download/v${OBP_VERSION}/obp-api-${OBP_VERSION}.war -O obp-api.war

# Create logs directory with proper permissions
RUN mkdir -p /opt/obp/logs && \
    chmod -R 777 /opt/obp/logs

# Create configuration directory
RUN mkdir -p /opt/obp/conf

# Copy configuration file
COPY ./config/default.props /opt/obp/conf/

# Expose the application port
EXPOSE 8080

# Run OBP API
CMD ["java", "-Dprops.resource.dir=/opt/obp/conf", "-jar", "obp-api.war"]