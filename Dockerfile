FROM lscr.io/linuxserver/webtop:ubuntu-xfce

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    ca-certificates \
    gnupg \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Add Lens repository and install official Lens Desktop
RUN curl -fsSL https://downloads.k8slens.dev/keys/gpg | gpg --dearmor | tee /usr/share/keyrings/lens-archive-keyring.gpg > /dev/null && \
    ARCH=$(dpkg --print-architecture) && \
    echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/lens-archive-keyring.gpg] https://downloads.k8slens.dev/apt/debian stable main" | tee /etc/apt/sources.list.d/lens.list > /dev/null && \
    apt-get update && \
    apt-get install -y lens && \
    rm -rf /var/lib/apt/lists/*

# Create custom services directory for LinuxServer init system
RUN mkdir -p /etc/services.d/lens

# Create the run script for Lens auto-start
RUN cat > /etc/services.d/lens/run << 'EOF'
#!/usr/bin/with-contenv bash

# Wait for desktop to be ready
sleep 10

# Set display
export DISPLAY=:1

# Run as the abc user
exec s6-setuidgid abc /usr/bin/lens-desktop --no-sandbox --disable-gpu-sandbox
EOF

RUN chmod +x /etc/services.d/lens/run

# Create desktop shortcut
RUN mkdir -p /config/Desktop && \
    cat > /config/Desktop/lens.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Lens Desktop
Comment=Kubernetes IDE
Exec=/usr/bin/lens-desktop --no-sandbox --disable-gpu-sandbox
Icon=lens
Terminal=false
Categories=Development;
EOF

RUN chmod +x /config/Desktop/lens.desktop

# Copy custom icon for web-lens-ide
COPY --chown=abc:abc web-lens-ide.png /usr/share/selkies/www/icon.png

# Set permissions for config file
RUN chown -R abc:abc /config