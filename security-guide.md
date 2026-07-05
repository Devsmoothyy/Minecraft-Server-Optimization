# Security Guide for Minecraft Servers

This covers infrastructure-level security — protecting the machine, the
process, and the network path. It does not cover in-game anti-cheat,
griefing prevention, or plugin permissions, which are gameplay/plugin
concerns outside this project's scope.

## 1. Run the server as a non-root user

Never run a Minecraft server (or Velocity) as `root`. If the JVM, a
plugin, or a dependency is ever compromised, running as root gives an
attacker full control of the machine instead of just the server's own
files.

```bash
# Create a dedicated, unprivileged user for the server
sudo useradd -r -m -d /srv/minecraft -s /bin/bash minecraft
sudo chown -R minecraft:minecraft /srv/minecraft

# Run the server as that user
sudo -u minecraft ./start.sh
```

If you're using systemd, set the user in the unit file:

```ini
# /etc/systemd/system/minecraft.service
[Service]
User=minecraft
Group=minecraft
WorkingDirectory=/srv/minecraft
ExecStart=/srv/minecraft/start.sh
```

## 2. Firewall recommendations

Only expose the ports players and admins actually need to reach directly.

- **Standalone server:** open only the Minecraft port (default `25565`)
  to the public. Everything else (SSH, RCON, panel ports) should be
  restricted to your own IP or a VPN.
- **Proxy setup (Velocity):** open the proxy's port to the public, but
  firewall the backend Paper server(s) so only the proxy's own IP (or
  localhost, if on the same box) can reach them. Players should never be
  able to connect to a backend server directly, bypassing the proxy.

Example with `ufw`:

```bash
# Public: proxy port only
sudo ufw allow 25565/tcp

# Backend server port — only reachable from the proxy's IP
sudo ufw allow from <proxy-ip> to any port 30001 proto tcp

# SSH — restrict to your own admin IP if possible
sudo ufw allow from <your-ip> to any port 22 proto tcp

sudo ufw enable
```

## 3. Protecting Velocity forwarding secrets

When using Velocity's modern forwarding, a shared secret authenticates
that player-info forwarding actually came from your proxy and wasn't
spoofed by a direct connection to the backend server.

- Generate the secret with Velocity itself (it writes a `forwarding.secret`
  file on first run) — don't hand-pick a weak or reused string.
- The **same** secret must be set in both `velocity.toml`-managed proxy
  config and the backend's `paper-global.yml` under
  `proxies.velocity.secret`.
- Treat this file like a password: correct file permissions (readable only
  by the service user), never commit it to a public repo, and never share
  it between unrelated server networks.

```bash
chmod 600 forwarding.secret
chown minecraft:minecraft forwarding.secret
```

- Set `proxies.velocity.enabled: true` and `proxy-protocol` appropriately
  in `paper-global.yml` **only** once forwarding is actually configured —
  see the comments in that file. Leaving `proxy-protocol: true` without a
  correctly configured proxy allows IP spoofing.

## 4. Secure RCON practices

RCON gives remote command execution on your server — treat credentials to
it with the same care as SSH access.

- Set a long, random `rcon.password` in `server.properties` (not covered
  in this repo's files, but worth calling out) — never leave it blank or
  use a short/common password.
- Firewall the RCON port (default `25575`) the same way as SSH: restrict
  it to your own admin IP or a VPN, never expose it publicly.
- If you don't actively use RCON, disable it (`enable-rcon=false`) rather
  than leaving an unused attack surface open.
- Avoid sending RCON commands over an untrusted network unencrypted —
  tunnel over SSH or a VPN if connecting remotely.

## 5. Basic production security checklist

- [ ] Server process runs as a dedicated non-root user
- [ ] Firewall allows only the ports that need to be public
- [ ] Backend servers behind a proxy are not directly reachable
- [ ] Velocity forwarding secret is set, matches on both ends, and is
      file-permission-restricted
- [ ] RCON is disabled, or password-protected and firewalled
- [ ] `online-mode` is `true` at whichever layer does authentication
      (proxy or standalone server)
- [ ] OS and Java are kept up to date with security patches
- [ ] Backups are stored somewhere other than the same disk as the live
      server (see the [production checklist](../production/production-checklist.md))
- [ ] SSH access uses key-based auth, not password auth, where possible

## 6. Out of scope

This guide intentionally does not cover plugin-level permissions systems,
anti-cheat configuration, or gameplay anti-grief tooling — those are
plugin concerns and outside this project's focus on core server
infrastructure.
