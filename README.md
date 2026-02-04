# SECCDC / CCDC Blue Team Playbook

**Purpose:** Defensive automation + templates for competition day.

## Quick Start (Jump Box)

### 1. Initial Setup
First, download the primary setup script, give it permissions, and run it to prep the environment:
```bash
# 1)Download the setup script

# 2)Make it executable
chmod +x 00_jumpbox_setup.sh

# 3)Run with sudo to install dependencies
sudo ./00_jumpbox_setup.sh

# 4)download the other two files into the newly created scripts folder
cd~/ccdc/scripts

5)make them executable
chmod +x 10_ccdc_service_check.sh
chmod +x 20_ccdc_backup_web.sh

