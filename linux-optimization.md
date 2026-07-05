# Linux Optimization Guide for Minecraft Servers

Minecraft server software runs like any other Java process, but a few
OS-level settings are commonly misconfigured and cause avoidable lag,
crashes, or connection issues. None of this is Minecraft-specific magic —
it's standard Linux server tuning that happens to matter a lot here
because of how many files and sockets a busy server touches.

This guide assumes a dedicated or semi-dedicated Linux box (Ubuntu/Debian/
CentOS-family) running the server as a systemd service or via a process
manager/screen/tmux session.

## 1. File descriptor limits

Every open world file, plugin JAR, log file, and player connection counts
against your process's open file-descriptor limit. The default limit on
most distros (1024) is too low for a server with many players, worlds, or
plugins, and you'll see cryptic "too many open files" errors when you hit it.

Edit `/etc/security/limits.conf` and add:

```
# /etc/security/limits.conf
*    soft    nofile    65535
*    hard    nofile    65535
minecraft soft nofile 65535
minecraft hard nofile 65535
```

Replace `minecraft` with the actual system user running the server (see
the [security guide](../security/security-guide.md) for why it shouldn't
be root). If you run the server via systemd, also set the limit in the
unit file, since systemd services don't always inherit `limits.conf`:

```ini
# /etc/systemd/system/minecraft.service
[Service]
LimitNOFILE=65535
```

After changing either file, log out/in (or restart the service) and
confirm with `ulimit -n` in the shell that will launch the server.

## 2. sysctl tweaks

These go in `/etc/sysctl.conf` (or a file under `/etc/sysctl.d/`) and take
effect after `sysctl -p`. Each one is explained — don't apply settings you
don't understand, and always test after changing.

```
# /etc/sysctl.d/99-minecraft.conf

# --- Networking: connection handling ---
# Increases the queue of pending connections. Useful during login bursts
# (e.g. right after a restart) so joins aren't dropped/delayed.
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 4096

# Reduces time sockets spend in TIME_WAIT, freeing them up faster.
# Helps servers/proxies that open and close many short-lived connections.
net.ipv4.tcp_fin_timeout = 15

# Enables reuse of TIME_WAIT sockets for new outgoing connections.
# Safe on modern kernels; helps proxy <-> backend server churn.
net.ipv4.tcp_tw_reuse = 1

# --- Memory: virtual memory behavior ---
# Lowers how aggressively the kernel swaps memory to disk. A Minecraft
# server should almost never be swapped — swapping the JVM heap causes
# severe, unpredictable lag spikes. 10 is a safe, swap-averse value.
vm.swappiness = 10

# Increases how much dirty (unwritten) memory can accumulate before the
# kernel forces a flush to disk. Helps smooth out disk I/O bursts during
# world saves on servers with enough RAM to spare.
vm.dirty_ratio = 20
vm.dirty_background_ratio = 10
```

Apply with:

```bash
sudo sysctl -p /etc/sysctl.d/99-minecraft.conf
```

## 3. Swap

- If your machine has swap enabled, keep `vm.swappiness` low (above) so
  the kernel avoids using it under normal conditions.
- A small swap file (1–2 GB) as an emergency buffer against an out-of-memory
  crash is reasonable, but swap should never be relied on for normal
  operation — it will make GC pauses and lag spikes far worse if the JVM
  heap ever touches it.
- Do **not** disable swap entirely on low-RAM boxes; a small safety net is
  better than an instant OOM-kill.

## 4. CPU governor

On bare-metal or dedicated hardware (not typically relevant for most VPS/
cloud instances, which usually don't expose this), make sure the CPU
frequency governor is set to `performance` rather than `powersave` or
`ondemand`, so single-core clock speed (which matters most for the main
tick loop — see [performance-tips.md](../performance/performance-tips.md))
isn't throttled down between bursts of load.

```bash
# Check current governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Set to performance (per-boot; use a systemd service or cpupower to persist)
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

## 5. Disk and filesystem

- Use an SSD/NVMe volume for the world folder — see
  [performance-tips.md](../performance/performance-tips.md) for why chunk
  I/O is a common bottleneck on spinning disks.
- If your filesystem supports it, mounting with `noatime` avoids the
  overhead of updating file-access timestamps on every chunk file read,
  which adds up on a world with thousands of region files.
  Keep at least 15–20% of the filesystem free to avoid degraded write performance.

```
# /etc/fstab example
/dev/sdX1  /srv/minecraft  ext4  defaults,noatime  0  2
```

## 6. General OS recommendations

- Run the server as a dedicated non-root user (covered in the
  [security guide](../security/security-guide.md)).
- Keep the OS and kernel patched — security updates matter even on a game
  server, especially if it's internet-facing.
- Use a process supervisor (systemd, or a lightweight process manager) so
  the server restarts automatically after a crash, rather than relying on
  someone noticing it's down.
- Monitor basic OS metrics (CPU, RAM, disk I/O, disk space) alongside
  in-game `/tps` and `/mspt` — an OS-level bottleneck often shows up in
  game performance before it's obvious anywhere else.
