#!/bin/sh
set -e

REPO="https://raw.githubusercontent.com/YOUR_USERNAME/passwall2-led-v6/main"
INSTALL_DIR="/root/passwall2-led-v6"

echo "Installing PassWall2 LED Controller V7.3..."

mkdir -p "$INSTALL_DIR/core" "$INSTALL_DIR/service" /etc/init.d

# Download files
curl -fsSL "$REPO/engine.sh" -o "$INSTALL_DIR/engine.sh"
curl -fsSL "$REPO/core/config.sh" -o "$INSTALL_DIR/core/config.sh"
curl -fsSL "$REPO/service/passwallled" -o "$INSTALL_DIR/service/passwallled"
curl -fsSL "$REPO/install.sh" -o "$INSTALL_DIR/install.sh"
curl -fsSL "$REPO/uninstall.sh" -o "$INSTALL_DIR/uninstall.sh"

chmod +x "$INSTALL_DIR/engine.sh" "$INSTALL_DIR/install.sh" "$INSTALL_DIR/uninstall.sh"
chmod +x "$INSTALL_DIR/service/passwallled"

cp "$INSTALL_DIR/service/passwallled" /etc/init.d/passwallled
chmod +x /etc/init.d/passwallled

/etc/init.d/passwallled enable
/etc/init.d/passwallled restart

echo "✅ PassWall2 LED Controller V7.3 Installed Successfully!"
echo "Edit config: $INSTALL_DIR/core/config.sh"
echo "Logs: logread | grep passwallled"
