#!/bin/sh
PING_TARGET_1="1.1.1.1"
PING_TARGET_2="8.8.8.8"
PING_TARGET_3="1.0.0.1"
PING_COUNT=3
PING_TIMEOUT=5
MIN_SUCCESS=2

LAT_GOOD=120
LAT_BAD=400

CACHE="/tmp/passwall_cache"
STATE_FILE="/tmp/passwall_state"
LOCK_DIR="/tmp/passwall_lock"

# === Google Wifi AC1304 Specific ===
LED_NAME="LED0_Blue"        # تغییر به Blue (یا Green تست کنید)
LED_PATH="/sys/class/leds/$LED_NAME"

FLAP_THRESHOLD=8
PING_COUNT=2
PING_TIMEOUT=3
MIN_SUCCESS=2
