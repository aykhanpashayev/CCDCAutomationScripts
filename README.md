# 🛡️ CCDC Palo Alto Firewall Playbook
## Blue Team Jump Box → Firewall Lockdown (FULL GUIDE)

> **Environment Assumption (IMPORTANT):**  
> You are already logged into the **Blue Team Linux jump box**.  
> This is the **first screen you see** after logging in (desktop with Terminal, Browser, RDP, etc).

> **Objective:**  
> Secure the Palo Alto firewall in the **first 30 minutes**:
> - Take exclusive control
> - Block Red Team access
> - Enable real inspection
> - Enforce deny-by-default
> - Keep scoring services alive

> **Golden Rule:**  
> Do NOT redesign the network.  
> Secure what already exists.

---

# 0️⃣ WHERE YOU ARE RIGHT NOW

You are on:
- A **Linux Blue Team jump box**
- Username like `blueteam`
- Desktop environment with:
  - Terminal
  - Browser
  - RDP Client
  - File System

❌ This is NOT the firewall  
✅ This is the machine you use to reach the firewall

---

# 1️⃣ FIND THE FIREWALL (FIRST TASK)

## 1.1 Check if a firewall console connection exists

1. Press: **Ctrl + Alt + Shift**
2. Open **Guacamole menu**
3. Click **Home / All Connections**

### Look for a connection named:
- `Firewall`
- `PA-VM`
- `PAN-OS`
- `PaloAlto`
- `VM-100`

👉 **If you see it, click it**  
That opens the **firewall console**.

➡️ Skip to **Section 3**

---

## 1.2 If NO firewall console exists (very common)

That means:
- Firewall must be accessed **from this jump box**
- Via **WebUI, SSH, or network access**

This is normal. Continue.

---

# 2️⃣ PREPARE THE JUMP BOX

## 2.1 Open Terminal

Double-click **Terminal**.

---

## 2.2 Find YOUR admin IP (IMPORTANT)

Run:
```bash
ip a
```
Write down:

Active interface (usually eth0)

IPv4 address (example: 10.x.x.x)

⚠️ This IP will be the ONLY IP allowed to manage the firewall

2.3 Look for environment notes (optional but smart)
Run:
```
ls
```
```
ls Desktop
```
Look for:

README files

Firewall IP hints

Connection scripts

Notes from organizers

3️⃣ LOCATE THE FIREWALL
3.1 Try common firewall management IPs
From Terminal:
```
ping 192.168.1.1
ping 192.168.0.1
ping 10.0.0.1
```
If any respond, that is likely the firewall.

3.2 Try accessing the WebUI
Open browser and go to:

https://<firewall-ip>
Example:
```
https://192.168.1.1
```
Ignore certificate warnings

Click Advanced → Proceed

3.3 If WebUI does NOT open (that’s OK)
Try SSH:
```
ssh admin@<firewall-ip>
```
If SSH fails → console access is required.

Go back and re-check Section 1.

4️⃣ FIREWALL CONSOLE LOGIN (CRITICAL)
When you see:
```
login:
```

Type:
```
admin
```
Password:
```
admin
```
Immediately verify:

show system info
✅ You must see PAN-OS information
❌ If you see Linux → wrong machine

5️⃣ FIRST 10 MINUTES — TAKE CONTROL
5.1 LOCK MANAGEMENT IMMEDIATELY
Stops Red Team from accessing WebUI.
```
configure
```
```
set deviceconfig system permitted-ip 127.0.0.1
```
```
commit
```
✅ Management is now console-only

5.2 DROP EXTERNAL INTERFACE (TEMPORARY)
Prevents inbound attacks while policies are empty.
```
configure
```
```
set network interface ethernet ethernet1/X link-state down
```
```
commit
```
(You will re-enable later.)

5.3 CHANGE ADMIN PASSWORD (MANDATORY)
```
configure
```
```
set mgt-config users admin password <STRONG_PASSWORD>
```
```
commit
```

Password must include:

8+ characters

Uppercase

Lowercase

Number or symbol

5.4 VERIFY ADMIN USERS
```
show admins all
```
Keep: admin

Remove anything else

6️⃣ SECURE MANAGEMENT ACCESS (MIN 10–15)
6.1 ALLOW MANAGEMENT ONLY FROM THIS JUMP BOX
Replace X.X.X.X with IP from Section 2.2.
```
configure
```
```
set deviceconfig system permitted-ip X.X.X.X
```
```
commit
```
❗ ONE IP ONLY

6.2 ENABLE ONLY SECURE MGMT SERVICES
From WebUI:

Device > Setup > Management > Management Interface
Enable:
```
HTTPS

SSH

Ping
```

Disable:
```
HTTP

Telnet

Anything unused
```
6.3 CONFIGURE DNS + NTP (REQUIRED)
WebUI:
```
Device > Setup > Services
DNS → REQUIRED

NTP → Recommended
```
7️⃣ LICENSING & UPDATES (MIN 15–20)
7.1 ACTIVATE LICENSES
WebUI:
```
Device > Licenses
Retrieve licenses
```
Confirm active

⚠️ No licenses = no inspection

7.2 INSTALL DYNAMIC UPDATES
WebUI:
```
Device > Dynamic Updates
Install:

Applications & Threats

Anti-Virus

URL Filtering DB

WildFire (if available)
```
8️⃣ DISCOVER DEPLOYMENT (MIN 20–25)
❌ DO NOT GUESS
✅ OBSERVE

Interfaces
show interface all
You See	Deployment
virtual-wire	VWire
vlan / l2	Layer 2
IP addresses	Layer 3
Zones
show zone
Routing
show routing route
Routes exist → Layer 3

No routes → VWire / L2

NAT
WebUI:
```
Policies > NAT
NAT rules → Layer 3

No NAT → VWire / L2
```

9️⃣ SECURITY PROFILES & POLICIES (MIN 25–30)
9.1 CREATE SECURITY PROFILE GROUP (MANDATORY)
WebUI:
```
Objects > Security Profiles
Create:

Anti-Virus

Anti-Spyware

Vulnerability Protection

URL Filtering

File Blocking

WildFire

Group name:

CCDC-SECURITY-PROFILES
```
9.2 POLICY ORDER (TOP → BOTTOM)
```
Infrastructure (DNS / NTP / updates)

Inbound scored services

East-West internal traffic

Outbound business traffic

Block bad / unknown URLs

DENY ALL (LOG ENABLED)
```

9.3 RULE REQUIREMENTS (NON-NEGOTIABLE)
Every ALLOW rule must:
```
Specify applications

Specify destination IPs

Use CCDC-SECURITY-PROFILES

Log at session end
```

❌ No any/any
❌ No rules without profiles

🔁 10️⃣ BACKUP & RECOVERY
10.1 BACK UP CONFIG (DO THIS EARLY)
```
scp export configuration to user@host:/path from running-config.xml
```
10.2 SNAPSHOT / RESET (IF AVAILABLE)
If snapshot/reset is provided:
```
Snapshot after policies

Label clearly
```
🚨 11️⃣ EMERGENCY RECOVERY
If firewall is compromised:
```
Restore snapshot / reset

Re-commit config

Verify management IP restriction

Resume operations
```
