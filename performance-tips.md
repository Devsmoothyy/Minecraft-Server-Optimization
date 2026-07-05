# Performance Optimization Tips

Practical, non-gameplay notes for keeping a Minecraft server running smoothly. These complement the config files elsewhere in this repo — read those first, since most of the actual tuning happens there.

## 1. Hardware & OS

- **CPU matters more than core count.** Minecraft's main tick loop is largely single-threaded, so a CPU with high single-core clock speed will outperform one with more, slower cores.
- **Use an SSD, not spinning disk.** Chunk I/O is a real bottleneck on HDDs, especially during world generation or backups.
- **Leave RAM headroom for the OS disk cache.** Don't allocate 100% of system RAM to the JVM — see `jvm/README.md` for sizing guidance. The OS uses spare RAM to cache recently-read chunk files, which speeds up world loading noticeably.

## 2. View distance and simulation distance

- View distance and simulation distance are the two settings with the single biggest effect on both CPU and RAM usage. Every additional ring of chunks is a lot more terrain to generate, tick, and send over the network.
- A good baseline for a small survival server: view distance 8–10, simulation distance 6–8. Raise only if you've confirmed you have CPU headroom.
- These live in `server.properties`, not in this repo's config files, since they're a basic server setting rather than an engine-tuning one — but they matter enough to call out here.

## 3. Pre-generate your world

- Chunk *generation* (creating new terrain) is far more expensive than chunk *loading* (reading existing terrain from disk). If players will explore a large area, pre-generate the world border ahead of time during off-peak hours instead of letting it happen live under player load.
- Most server platforms (Paper included) support a world-border pre-generation task; check your version's documentation for the exact command.

## 4. Watch redstone and farms

- Large redstone contraptions and automatic farms are consistently the top cause of TPS drops on survival servers, because they generate constant block updates.
- The `redstone-implementation` option in `paper/paper-world-defaults.yml` (set to `alternate-current` in this repo) is a drop-in performance improvement for redstone-heavy builds with no behavior change to build logic.
- Hopper-based item sorting systems are the other common offender — the `hopper` tuning in `paper/paper-world-defaults.yml` and `spigot/spigot.yml` addresses this.

## 5. Entity counts

- Mob farms, item duplication glitches (unintentional ones), and large animal pens are the most common source of runaway entity counts.
- The `entity-activation-range` and `entity-tracking-range` settings in `spigot/spigot.yml` are your main lever here — they don't reduce how many mobs *exist*, but they reduce how much CPU/network is spent on ones far from any player.
- If entity counts are a recurring problem, a scheduled task that clears item drops/entities in unloaded or rarely-visited areas is more effective than lowering activation ranges further.

## 6. Monitor before you tune

- Don't guess — measure. Use Paper/Spigot's built-in `/tps` and `/mspt` commands (or a timings/spark report) to see actual tick times before changing settings, and again afterward to confirm the change helped.
- A `spark` profile (or Paper's built-in profiler) will show you exactly which plugin, world, or subsystem is consuming tick time — far more useful than tuning blind.

## 7. Backups shouldn't block the main thread

- Make sure your backup solution snapshots or copies world files without pausing the server (e.g. filesystem snapshots, or a plugin that offloads compression to a background thread). A backup that blocks the main thread on a large world is a common, avoidable source of major lag spikes.

## 8. Plugins are usually the real bottleneck

- On most servers with moderate player counts, poorly-written plugins — not the server engine itself — are the biggest performance cost. This repo intentionally doesn't cover plugin configuration, but if you've applied everything here and are still seeing poor TPS, a spark profile will usually point straight at the culprit.
