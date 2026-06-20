# passwall2-led-ac1304
# PassWall2 LED Controller V7.3

**موتور هوشمند وضعیت شبکه و VPN برای LED روتر OpenWrt**

نسخه نهایی: **Production Hardened Single-Process State Machine**

### ویژگی‌ها
- تشخیص ترکیبی VPN (interface + process)
- پینگ چندمرحله‌ای مقاوم (multi-target)
- ماشین حالت (FSM) با Hysteresis و Anti-Livelock
- Single-process engine (بسیار سبک)
- قفل atomic + حفاظت از deadlock
- LED detection هوشمند
- Logging فقط هنگام تغییر وضعیت

### نصب سریع
```sh
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/passwall2-led-v6/main/install.sh | sh
