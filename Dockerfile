FROM ubuntu:24.04

# Install required monitoring commands
RUN apt-get update && apt-get install -y \
    bash \
    sysstat \
    procps \
    gawk \
    coreutils \
    findutils \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy monitoring script
COPY server_health.sh .

# Make script executable
RUN chmod +x server_health.sh

# Run monitoring script
CMD ["/bin/bash", "./server_health.sh"]
