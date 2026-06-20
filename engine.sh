#!/bin/sh
. /root/passwall2-led-v6/core/config.sh

acquire_lock() {
    while ! mkdir "$LOCK_DIR" 2>/dev/null; do
        if [ -d "$LOCK_DIR" ]; then
            LOCK_AGE=$(($(date +%s) - $(stat -c %Y "$LOCK_DIR" 2>/dev/null || echo 0)))
            [ "$LOCK_AGE" -gt 30 ] && rmdir "$LOCK_DIR" 2>/dev/null || true
        fi
        sleep 0.1
    done
}

release_lock() {
    rmdir "$LOCK_DIR" 2>/dev/null || true
}

get_state() {
    [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo "S0"
}

set_state() {
    echo "$1" > "$STATE_FILE"
    sync 2>/dev/null || true
}

LAST_STATE=""
FLAP_COUNT=0

while true; do
    acquire_lock
    NOW=$(date +%s)
    STATE=$(get_state)

    if [ -f "$CACHE" ]; then
        READ_TIME=$(head -n1 "$CACHE" 2>/dev/null | cut -d'|' -f2 || echo 0)
        if [ $((NOW - READ_TIME)) -lt 5 ]; then
            CACHE_LINE=$(tail -n1 "$CACHE")
        else
            VPN=0; NET=0; LAT=9999; SUCCESS=0

            if ip -4 addr show | grep -Eq "tun[0-9]|wg[0-9]|ppp[0-9]"; then
                VPN=1
            elif pgrep -f "xray|sing-box|v2ray|hysteria|clash|tun2socks" >/dev/null 2>&1; then
                VPN=1
            fi

            for TARGET in "$PING_TARGET_1" "$PING_TARGET_2" "$PING_TARGET_3"; do
                if ping -c "$PING_COUNT" -W "$PING_TIMEOUT" "$TARGET" >/dev/null 2>&1; then
                    SUCCESS=$((SUCCESS + 1))
                    RESULT=$(ping -c 1 -W "$PING_TIMEOUT" "$TARGET" 2>/dev/null | grep -o 'time=[0-9.]\+' | cut -d= -f2 | cut -d. -f1)
                    [ -n "$RESULT" ] && LAT=$RESULT
                fi
            done
            [ $SUCCESS -ge "$MIN_SUCCESS" ] && NET=1

            CACHE_LINE="v3|$NOW|$VPN|$NET|$LAT"
            echo "$CACHE_LINE" > "$CACHE"
        fi
    else
        VPN=0; NET=0; LAT=9999
        CACHE_LINE="v3|$NOW|$VPN|$NET|$LAT"
        echo "$CACHE_LINE" > "$CACHE"
    fi

    IFS='|' read -r _ _ VPN NET LAT _ <<EOF
$CACHE_LINE
EOF
    [ -z "$LAT" ] && LAT=9999

    SCORE=0
    [ "$NET" -eq 1 ] && SCORE=$((SCORE + 40))
    [ "$VPN" -eq 1 ] && SCORE=$((SCORE + 30))
    if [ "$LAT" -lt "$LAT_GOOD" ]; then
        SCORE=$((SCORE + 30))
    elif [ "$LAT" -lt "$LAT_BAD" ]; then
        SCORE=$((SCORE + 15))
    else
        SCORE=$((SCORE + 5))
    fi
    [ "$NET" -eq 0 ] && SCORE=0

    case "$STATE" in
        S0) NEW=$([ "$NET" -eq 1 ] && echo "S1" || echo "S0") ;;
        S1) NEW=$([ "$VPN" -eq 1 ] && echo "S2" || echo "S1") ;;
        S2)
            if [ "$NET" -eq 0 ]; then NEW="S6"
            elif [ "$SCORE" -lt 55 ]; then NEW="S3"
            else NEW="S2"; fi
            ;;
        S3)
            if [ "$SCORE" -gt 70 ]; then NEW="S2"
            elif [ "$SCORE" -lt 30 ]; then NEW="S4"
            else NEW="S3"; fi
            ;;
        S4)
            FLAP_COUNT=$((FLAP_COUNT + 1))
            if [ "$SCORE" -gt 60 ] || [ "$FLAP_COUNT" -gt "$FLAP_THRESHOLD" ]; then
                NEW="S3"; FLAP_COUNT=0
            elif [ "$SCORE" -lt 25 ]; then
                NEW="S6"; FLAP_COUNT=0
            else
                NEW="S4"
            fi
            ;;
        S6) NEW=$([ "$NET" -eq 1 ] && echo "S1" || echo "S6") ;;
        *) NEW="S0" ;;
    esac

    [ "$NEW" != "$STATE" ] && set_state "$NEW"
    STATE="$NEW"

    echo "v3|$NOW|$VPN|$NET|$LAT|$SCORE|$STATE" > "$CACHE"
    release_lock

    # Safe LED Driver
    if [ ! -d "$LED_PATH" ]; then
        for L in /sys/class/leds/*; do
            case "$(basename "$L")" in
                *status*|*internet*|*wan*|*blue*|*white*)
                    LED_PATH="$L"; break ;;
            esac
        done
        [ ! -d "$LED_PATH" ] && LED_PATH="/sys/class/leds/$(ls /sys/class/leds/ 2>/dev/null | grep -E 'status|wan|internet' | head -n1)"
    fi

    {
        echo none > "$LED_PATH/trigger" 2>/dev/null || true
        case "$STATE" in
            S2) echo heartbeat > "$LED_PATH/trigger" ;;
            S3)
                echo timer > "$LED_PATH/trigger"
                echo 500 > "$LED_PATH/delay_on"
                echo 700 > "$LED_PATH/delay_off"
                ;;
            S4)
                echo timer > "$LED_PATH/trigger"
                echo 200 > "$LED_PATH/delay_on"
                echo 200 > "$LED_PATH/delay_off"
                ;;
            S6)
                echo timer > "$LED_PATH/trigger"
                echo 80 > "$LED_PATH/delay_on"
                echo 80 > "$LED_PATH/delay_off"
                ;;
            S1) echo default-on > "$LED_PATH/trigger" ;;
            S0|*)
                echo none > "$LED_PATH/trigger"
                echo 0 > "$LED_PATH/brightness" 2>/dev/null || true
                ;;
        esac
    } &

    if [ "$STATE" != "$LAST_STATE" ]; then
        logger -p daemon.info -t passwallled "State:${STATE} Score:${SCORE} Lat:${LAT} VPN:${VPN} Net:${NET}"
    fi
    LAST_STATE="$STATE"

    sleep $([ "$STATE" = "S0" ] && echo 3 || echo 6)
done
