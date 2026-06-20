#!/bin/sh
# ================== PassWall2 LED Controller V7.3 Config ==================
PING_TARGET_1="1.1.1.1"
PING_TARGET_2="8.8.8.8"
PING_TARGET_3="1.0.0.1"

LAT_GOOD=120
LAT_BAD=400

CACHE="/tmp/passwall_cache"
STATE_FILE="/tmp/passwall_state"
LOCK_DIR="/tmp/passwall_lock"

LED_NAME="white:status"
LED_PATH="/sys/class/leds/$LED_NAME"

# Tuning Parameters
FLAP_THRESHOLD=8
PING_COUNT=2
PING_TIMEOUT=3
MIN_SUCCESS=2
# =================================================================
