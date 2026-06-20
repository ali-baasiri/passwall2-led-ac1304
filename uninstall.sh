#!/bin/sh
echo "🛑 Uninstalling PassWall2 LED Controller..."

/etc/init.d/passwallled stop 2>/dev/null || true
/etc/init.d/passwallled disable 2>/dev/null || true
rm -f /etc/init.d/passwallled
rm -rf /root/passwall2-led-v6
rm -f /tmp/passwall_*

echo "✅ حذف کامل انجام شد."
