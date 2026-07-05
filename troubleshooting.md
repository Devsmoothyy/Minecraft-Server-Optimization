# Troubleshooting Guide

Practical, non-plugin-specific starting points for the most common
Minecraft server problems. The goal here is to point you at the right
*category* of cause and the config in this repo that's relevant — not to
replace measuring with `/tps`, `/mspt`, or a `spark` profile, which will
always give you a more precise answer than a general guide can.

## Low TPS (tick rate below 20)

**Likely causes, roughly in order of frequency:**
1. Too many active entities (mob farms, animal pens, item drops) — see
   `entity-activation-range` in [`spigot.yml`](../spigot/spigot.yml) and
   `entity-tracking-range` in
   [`paper-world-defaults.yml`](../paper/paper-world-defaults.yml).
2. Redstone/hopper-heavy farms — see the `redstone-implementation` and
   `hopper` settings in
   [`paper-world-defaults.yml`](../paper/paper-world-defaults.yml).
3. View/simulation distance set too high for available CPU — see
   [`performance-tips.md`](../performance/performance-tips.md).
4. A poorly optimized plugin (most common root cause on real servers,
   though outside this repo's scope to configure) — a `spark` profile
   will point directly at the offending plugin/world/subsystem.

**What to do:** run a `spark` profile (or use Paper's built-in profiler)
during the low-TPS period rather than guessing. It will tell you whether
the time is going to entities, chunk loading, redstone, or a specific
plugin, which determines which fix above actually applies.

## High RAM usage

**Likely causes:**
1. Heap size (`-Xmx`) set larger than actually needed, or the JVM
   accumulating garbage faster than it's collected — review the GC flags
   in [`jvm/README.md`](../jvm/README.md).
2. Large view/simulation distance multiplying loaded-chunk memory cost.
3. A memory leak in a plugin (again, outside this repo's scope, but a
   heap dump/profile will confirm it if RAM grows steadily over days
   rather than stabilizing).

**What to do:** check whether RAM usage climbs and plateaus (normal — the
JVM fills the heap and then GCs) or climbs continuously without ever
dropping (a leak). Continuous, unbounded growth points to a plugin or a
JVM misconfiguration, not normal Minecraft behavior.

## High CPU usage

**Likely causes:**
1. Entity/redstone/hopper load — same first two causes as "Low TPS" above,
   since CPU exhaustion is usually *why* TPS drops.
2. Chunk generation happening live under player load instead of being
   pre-generated — see the pre-generation note in
   [`performance-tips.md`](../performance/performance-tips.md).
3. Compression or encryption overhead misconfigured on a proxy — see
   `compression-threshold` in [`velocity.toml`](../velocity/velocity.toml).

**What to do:** distinguish single-core saturation (main tick thread —
points to entities/redstone/plugins) from all-cores saturation (chunk
generation, world I/O, or another process on the same box competing for
CPU).

## Long startup times

**Likely causes:**
1. Disk I/O bottleneck reading a large world from a slow disk — see the
   SSD recommendation in [`performance-tips.md`](../performance/performance-tips.md).
2. Large number of plugins doing expensive work during their `onEnable()`
   (outside this repo's scope, but worth noting as a common cause).
3. JVM class-loading/JIT warmup — largely unavoidable, but consistent
   across restarts; if startup time is *increasing* over time, that's a
   different problem (usually world size or plugin count growth).

**What to do:** time how long the world-loading phase specifically takes
versus the phase before/after it in the console log. A slow world-load
phase points to disk I/O; a slow plugin-loading phase points to plugins.

## Network latency (high or inconsistent ping)

**Likely causes:**
1. Physical distance between the server and players — no config fixes
   this; see the [network guide](../network/network-optimization.md).
2. An oversubscribed host or noisy-neighbor VPS.
3. Compression settings tuned for bandwidth at the cost of CPU/latency on
   an already CPU-constrained box — see `compression-threshold` in
   [`velocity.toml`](../velocity/velocity.toml).
4. TCP settings not tuned for the connection pattern — see the
   [network guide](../network/network-optimization.md) for sysctl options.

**What to do:** use `mtr` (not just `ping`) between a representative
player location and the server to see where in the route latency/packet
loss is actually being introduced, rather than assuming it's the server.

## Slow chunk loading

**Likely causes:**
1. Disk I/O — chunk *generation* especially is expensive; see
   [`performance-tips.md`](../performance/performance-tips.md) on
   pre-generating worlds.
2. `chunk-system` worker/IO thread settings in
   [`paper-global.yml`](../paper/paper-global.yml) left on `auto` while
   competing with another CPU-heavy process on the same box (a proxy,
   database, or panel) — consider reserving cores if so.
3. `max-auto-save-chunks-per-tick` and `prioritize-chunk-updates` in
   [`paper-world-defaults.yml`](../paper/paper-world-defaults.yml) tuned
   for a different priority (bandwidth vs latency) than what you actually
   want.

**What to do:** check whether slowness happens on first-time exploration
(generation-bound — pre-generate) or when revisiting already-generated
areas (I/O-bound — check disk type and `noatime` mount option in the
[Linux guide](../linux/linux-optimization.md)).

## General approach

For all of the above: change one thing at a time, measure with `/tps`,
`/mspt`, or a `spark` profile before and after, and keep notes. Tuning
blind — changing several settings at once "to be safe" — makes it
impossible to know which change actually helped, and some settings trade
one resource for another (CPU for bandwidth, memory for speed) rather than
being free wins.
