# Network Optimization Guide for Minecraft Servers

Minecraft is latency-sensitive in ways that aren't always obvious: block
placement, combat, and redstone all feel worse when packets are delayed
or bunched up, even if TPS is perfectly healthy. This guide covers basic
network tuning at the OS and application-config level. It complements,
rather than duplicates, the Velocity-specific settings already documented
in [`velocity/velocity.toml`](../velocity/velocity.toml).

## 1. TCP tuning (OS level)

A few kernel-level TCP settings help with the connection patterns typical
of a Minecraft server (many small packets, frequent short-lived proxy ↔
backend connections). Add these alongside the settings in the
[Linux guide](../linux/linux-optimization.md):

```
# /etc/sysctl.d/99-minecraft-network.conf

# Increases the receive/send buffer ceiling so bursts of packets
# (e.g. chunk data) don't get bottlenecked by small default buffers.
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# Enables TCP window scaling, letting connections use larger buffers —
# helps throughput on higher-latency links (e.g. players far from the
# server region).
net.ipv4.tcp_window_scaling = 1

# Enables a modern, low-latency-friendly congestion control algorithm.
# BBR generally outperforms the older CUBIC default for real-time,
# latency-sensitive traffic like game packets. Requires a reasonably
# modern kernel (4.9+).
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
```

Check whether BBR is available before enabling it:

```bash
sysctl net.ipv4.tcp_available_congestion_control
```

If `bbr` isn't listed, stick with the kernel default (`cubic`) rather than
forcing an unsupported algorithm.

## 2. Low-latency recommendations

- **Pick a server region close to your player base.** No amount of tuning
  beats physical distance — ping is bounded by the speed of light over
  the actual network path. This matters more than almost anything else on
  this page.
- **Avoid oversubscribed shared hosting** for latency-sensitive servers
  (competitive PvP, minigames). A cheap VPS on a congested host can add
  unpredictable jitter that no amount of config tuning fixes.
- **Wired > Wi-Fi, always**, if you're self-hosting on a home connection.
  Wi-Fi introduces variable latency and packet loss that's invisible in
  normal browsing but very noticeable in-game.
- **Don't over-compress.** The `compression-threshold` setting in
  `velocity.toml` (and the equivalent in `server.properties` for a
  standalone server) trades CPU for bandwidth. Very aggressive compression
  settings can add latency on CPU-constrained boxes — the defaults
  documented in this repo's `velocity.toml` are a reasonable balance.

## 3. General networking best practices

- **Use a proxy (Velocity) only if you need one** — running multiple
  backend servers, or wanting seamless server-switching. A single
  standalone server talking directly to players has one less network hop
  and one less thing to misconfigure.
- **Keep `online-mode` correct for your setup.** A public server should
  have `online-mode: true` at the point where authentication actually
  happens (the proxy if you use one, the backend server if you don't).
  Getting this wrong is a security issue, not just a networking one — see
  the [security guide](../security/security-guide.md).
- **Use modern forwarding (Velocity's native forwarding) instead of
  legacy/BungeeCord-style forwarding** when running Paper behind Velocity.
  It's simpler to configure correctly and doesn't require the
  `bungeecord: true` compatibility flag. See the `proxies` section in
  [`paper-global.yml`](../paper/paper-global.yml) and the matching
  `secret` field in `velocity.toml`.
- **Firewall unused ports.** If you're running a proxy, the backend
  server(s) shouldn't be reachable directly from the internet — only from
  the proxy itself. Covered in the [security guide](../security/security-guide.md).
- **Monitor packet loss and jitter**, not just ping. A stable 80ms
  connection feels better than a jittery 40ms one. Tools like `mtr` are
  more useful than a single `ping` for diagnosing route issues between
  your server and a player base.

## DNS

- Use a reliable DNS provider for your domain.
- Set a sensible TTL if you expect to change server IPs.
- Avoid unnecessary DNS chains or redirects.

## 4. Keep it simple

Most network complaints on small-to-medium servers trace back to one of:
server region/distance, an oversubscribed host, or a misconfigured proxy —
not missing kernel tweaks. Apply the sysctl settings above as a sensible
baseline, then look at hosting/region choices before going further down
the tuning rabbit hole.
