# NTFS Manager Docker Image
# Multi-stage build for optimal image size and security

# Build stage
FROM python:3.11-slim as builder

# Set build arguments
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

# Set labels
LABEL maintainer="MagDriveX <sales@magdrivex.com>"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="NTFS Manager"
LABEL org.label-schema.description="Professional NTFS drive management for Linux"
LABEL org.label-schema.url="https://github.com/magdrivex/ntfs-manager"
LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL org.label-schema.vcs-url="https://github.com/magdrivex/ntfs-manager.git"
LABEL org.label-schema.vendor="MagDriveX"
LABEL org.label-schema.version=$VERSION
LABEL org.label-schema.schema-version="1.0"

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    libgtk-3-dev \
    libgirepository1.0-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libgdk-pixbuf2.0-dev \
    libnotify-dev \
    ntfs-3g-dev \
    policykit-1-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY ntfs-manager-production/requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Copy application code
COPY ntfs-complete-manager-gui/ ./gui/
COPY ntfs-manager-production/ ./production/
COPY ntfs-nautilus-extension/ ./extension/
COPY modules/ ./modules/

# Install application
RUN cd gui && \
    pip install --user . && \
    cd ../production && \
    pip install --user .

# Production stage
FROM python:3.11-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libgtk-3-0 \
    libgirepository1.0-1 \
    libcairo2 \
    libpango1.0-0 \
    libgdk-pixbuf2.0-0 \
    libnotify4 \
    ntfs-3g \
    policykit-1 \
    dbus-x11 \
    x11-utils \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r ntfsmanager && \
    useradd -r -g ntfsmanager -G audio,video,plugdev -d /app -s /bin/bash ntfsmanager

# Set working directory
WORKDIR /app

# Copy installed Python packages from builder
COPY --from=builder /root/.local /home/ntfsmanager/.local

# Copy application data
COPY --from=builder /app /app

# Set ownership
RUN chown -R ntfsmanager:ntfsmanager /app /home/ntfsmanager

# Switch to non-root user
USER ntfsmanager

# Set environment variables
ENV PATH=/home/ntfsmanager/.local/bin:$PATH
ENV PYTHONPATH=/app
ENV DISPLAY=:0

# Expose application
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8080/health')" || exit 1

# Default command
CMD ["python", "/app/gui/main.py", "--no-sandbox"]

# Metadata
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="NTFS Manager"
LABEL org.label-schema.description="Professional NTFS drive management for Linux"
LABEL org.label-schema.url="https://github.com/magdrivex/ntfs-manager"
LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL org.label-schema.vcs-url="https://github.com/magdrivex/ntfs-manager.git"
LABEL org.label-schema.vendor="MagDriveX"
LABEL org.label-schema.version=$VERSION
LABEL org.label-schema.schema-version="1.0"
