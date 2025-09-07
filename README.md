# MOTD Service Status Monitor

A lightweight **service status monitor** written in pure Bash.  
It is intended to be added to the update-motd script set, to give you a quick view of critical services when logging in to a server.  To ensure safety, this has minimal **external dependencies**.

---

## Features

- **Pure Bash** – no Python, Perl, or jq required  
- **Configurable per-host** – picks config file by FQDN, short hostname, or default  
- **Checks programs** – runs commands and matches optional expected output  
- **Checks Docker containers** – inspects container state if Docker is installed  
- **Colorized output** – green check, red cross, yellow question mark  
- **Column layout with auto-wrapping** – adapts to your terminal width  

---

## Example Output

```
Services:
✓ named           ✓ kea-dhcp4       ✓ Unifi
✗ redis           ? docker
```

- **Green ✓** = running/healthy  
- **Red ✗** = failed/unexpected  
- **Yellow ?** = unknown (e.g., Docker not installed)  

---

## Installation

Clone or copy the script somewhere in your `$PATH` (e.g., `/usr/local/bin/`):

```bash
git clone https://github.com/yourusername/motd-status-monitor.git
cd motd-status-monitor
chmod +x status-monitor.sh
```

---

## Configuration

The script loads a configuration file containing two arrays:

```bash
# config.conf (example)

# Programs to check:
# Format: "Name|command|expected_output"
PROGRAMS=(
  "named|systemctl is-active named|active"
  "kea-dhcp4|systemctl is-active kea-dhcp4|active"
)

# Docker containers to check:
# Format: "Name|container_name"
CONTAINERS=(
  "Unifi|unifi-controller"
  "Redis|redis"
)
```

### Config file resolution order

When run without arguments, the script looks for a config file in this order:

1. `<script-dir>/<fqdn>.conf`  
2. `<script-dir>/<hostname>.conf`  
3. `<script-dir>/config.conf` (default)  

You can also specify a config explicitly:

```bash
./status-monitor.sh /path/to/custom.conf
```

---

## Usage

Run directly:

```bash
./status-monitor.sh
```

Integrate into your system’s **Message of the Day (MOTD)** by adding a call to the script in `/etc/update-motd.d/`.

---

## Environment Variables

- `NAME_WIDTH` – width reserved for service names (default: `14`)  
- `GAP` – spaces between columns (default: `2`)  

Example:

```bash
NAME_WIDTH=20 GAP=4 ./status-monitor.sh
```

---

## Requirements

- `bash` 4+  
- Optional: `timeout` (for program checks)  
- Optional: `docker` (for container checks)  

---

## License

MIT License – see [LICENSE](LICENSE) for details.
