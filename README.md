# Assignment 1 — Linux Diagnostic Toolkit

A set of Bash scripts that collect system information, check disk usage and perform basic network checks. All values are read from the system at runtime, and every run is logged under `logs/`.

## Requirements

- Linux (tested on Ubuntu 26.04 under WSL2)
- Bash 4+
- Packages: `iproute2` (`ip`), `iputils-ping` (`ping`), `netcat-openbsd` (`nc`), `libc-bin` (`getent`)

Install on Ubuntu/Debian:

```bash
sudo apt update
sudo apt install -y iproute2 iputils-ping netcat-openbsd
```

## Setup

```bash
git clone https://github.com/Wonderfullymade01/assignment-1.git
cd assignment-1
chmod +x *.sh
```

## Usage

### system-info.sh

Displays hostname, current user, date/time, operating system, kernel version, uptime, CPU, memory and current directory.

```bash
./system-info.sh
```

### disk-check.sh

```bash
./disk-check.sh <threshold> [path]
```

- `threshold`: whole number from 1 to 100
- `path`: optional, defaults to `/`

| Exit code | Meaning |
|---|---|
| 0 | Usage is below the threshold |
| 1 | Usage has reached or exceeded the threshold (or could not be read) |
| 2 | Invalid input |

Examples:

```bash
./disk-check.sh 80
./disk-check.sh 90 /home
```

### network-check.sh

```bash
./network-check.sh <hostname-or-ip> [port]
```

Validates the host, resolves it to an IP address, pings it, shows network interfaces and, if a port is given, checks TCP connectivity.

- `port`: optional, whole number from 1 to 65535

| Exit code | Meaning |
|---|---|
| 0 | All checks passed |
| 1 | A network check failed (resolve, ping or port) |
| 2 | Invalid input |

Examples:

```bash
./network-check.sh google.com
./network-check.sh google.com 443
```

## Logging

Each script writes timestamped entries to its own file in `logs/`:

- `logs/system-info.log`
- `logs/disk-check.log`
- `logs/network-check.log`

Example entry:

```
2026-10-28 13:17:44 [network-check] TCP port 443 on 'google.com' is open
```

Log files are ignored by Git (`.gitignore`); only `logs/.gitkeep` is committed.

## Testing

Run the grader:

```bash
./grade.sh
```

Manual checks:

```bash
./disk-check.sh 0;   echo $?   # 2 (invalid)
./disk-check.sh abc; echo $?   # 2 (invalid)
./network-check.sh localhost 65536; echo $?   # 2 (invalid port)
./network-check.sh no-such-host.invalid; echo $?   # 1 (cannot resolve)
```

## Assumptions

- Some networks block ping (ICMP), so a failed ping returns exit code 1 even if the host is actually up.
- When a host resolves to several addresses, only the first one is displayed.

## Git workflow

Development was done on the `feature/scripts` branch and merged into `main`.
