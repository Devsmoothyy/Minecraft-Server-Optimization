# Production Checklist

A pre-launch checklist for taking a Minecraft server from "configured" to
"ready for real players." Work through this after applying the configs in
this repo and before announcing/opening the server publicly.

## Java & JVM

- [ ] Running the Java version recommended by your server software's
      current release notes for your Minecraft version (see
      [`jvm/README.md`](../jvm/README.md) — this changes over time, so
      re-check it rather than assuming last year's version is still right).
- [ ] JVM flags verified against [`jvm/README.md`](../jvm/README.md) and
      [`start.sh`](../jvm/start.sh), with `-Xms`/`-Xmx` set to the **same**
      value.
- [ ] Heap size sized appropriately for available RAM (roughly 60–75% of
      total system RAM — see the sizing table in `jvm/README.md`), leaving
      headroom for the OS disk cache.

## System

- [ ] Server clock is synchronized (NTP enabled).
- [ ] Enough free disk space remains for logs, backups, and world growth.
- [ ] SSD/NVMe storage is used for production servers whenever possible.

## Server configuration

- [ ] `view-distance` and `simulation-distance` set deliberately in
      `server.properties` (not left on an untested default) — see
      [`performance-tips.md`](../performance/performance-tips.md) for
      baseline recommendations.
- [ ] `paper-global.yml` and `paper-world-defaults.yml` reviewed against
      the annotated versions in this repo, and merged with any
      version-specific stock options you still need.
- [ ] If running behind a proxy: **modern forwarding** configured and
      verified (secret matches on both proxy and backend, `online-mode`
      set correctly at the proxy, backend not directly reachable — see the
      [security guide](../security/security-guide.md)).
- [ ] `spigot.yml` entity activation/tracking ranges reviewed for your
      expected player count and world type.

## Startup & process management

- [ ] Startup script (`start.sh` or equivalent) reviewed: correct RAM
      value, correct server JAR path, executable permissions set.
- [ ] Server runs under a process supervisor (systemd or equivalent) that
      restarts it automatically on crash.
- [ ] `restart-on-crash` / equivalent watchdog behavior tested at least
      once (deliberately kill the process and confirm it comes back).
- [ ] Server does **not** run as root (see the
      [security guide](../security/security-guide.md)).

## Backups

- [ ] Automated backup schedule in place (not just a manual one-off
      backup before launch).
- [ ] Backups are stored off the same disk/volume as the live server —
      a disk failure shouldn't take out both the server and its backups.
- [ ] **A restore has actually been tested.** An untested backup is not a
      verified backup — restore it to a staging environment and confirm
      the world loads correctly before relying on it.
- [ ] Backup process doesn't block the main thread (see
      [`performance-tips.md`](../performance/performance-tips.md) — use
      filesystem snapshots or background compression).

## Networking & security

- [ ] Firewall enabled, only necessary ports exposed publicly (see the
      [security guide](../security/security-guide.md)).
- [ ] RCON disabled, or password-protected and firewalled to admin IPs
      only.
- [ ] Basic TCP/sysctl tuning applied if expecting meaningful concurrent
      player counts (see the [network guide](../network/network-optimization.md)).

## Performance validation

- [ ] Server load-tested (even informally — have several people join and
      move around/build/fight) before opening publicly.
- [ ] `/tps` and `/mspt` checked under that test load, not just at idle.
- [ ] A baseline `spark` profile or timings report taken while healthy, so
      you have something to compare against if problems show up later.
- [ ] World pre-generated for the expected initial playable area, if
      you're expecting exploration-heavy early activity (see
      [`performance-tips.md`](../performance/performance-tips.md)).

## Final pass

- [ ] All config file changes documented somewhere (a changelog, commit
      history, or even just comments) so future-you knows what was changed
      and why.
- [ ] A rollback plan exists: you know how to revert to stock configs or a
      prior backup quickly if launch reveals a serious problem.
