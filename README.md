# JVM Flags for Minecraft Servers

Minecraft servers are extremely sensitive to **garbage collection pauses** — a bad GC pause is what causes visible "lag spikes" even when average CPU usage looks fine. The flags below configure the G1 garbage collector (the recommended collector for Minecraft) to minimize pause times.

These are based on the widely-used, community-tested "Aikar's flags" approach, kept minimal and explained rather than copy-pasted as a black box.

## The flags, explained

| Flag | What it does |
|---|---|
| `-Xms<size> -Xmx<size>` | Sets **minimum and maximum** heap size. Set them **equal** — a server that has to resize its heap mid-run causes extra GC pauses. |
| `-XX:+UseG1GC` | Selects the G1 garbage collector — the best general-purpose choice for Minecraft's allocation pattern. |
| `-XX:+ParallelRefProcEnabled` | Processes reference objects (weak/soft refs) in parallel during GC instead of single-threaded, shortening pause times. |
| `-XX:MaxGCPauseMillis=200` | Tells G1 to *target* pauses of ~200ms. G1 uses this as a goal, not a hard guarantee, but it steers behavior in the right direction. |
| `-XX:+UnlockExperimentalVMOptions` | Required to enable some of the G1 tuning flags below on older JDKs. |
| `-XX:+DisableExplicitGC` | Ignores `System.gc()` calls from plugins that call it manually (some badly-written plugins do this and cause needless full GCs). |
| `-XX:MaxTenuringThreshold=1` | Objects are promoted to "old generation" after surviving just 1 GC cycle. Tuned for Minecraft's pattern of many short-lived objects (entities, packets). |
| `-XX:G1NewSizePercent=30` / `-XX:G1MaxNewSizePercent=40` | Sizes the "young generation" heap region as 30–40% of the heap — Minecraft allocates a huge number of short-lived objects, so a larger young gen reduces how often minor GCs run. |
| `-XX:G1HeapRegionSize=8M` | Size of each G1 heap region. 8M works well for the multi-GB heaps typical of Minecraft servers. |
| `-XX:G1ReservePercent=20` | Reserves 20% of the heap as spare space G1 avoids using, reducing the chance of an emergency full GC ("to-space exhausted"). |
| `-XX:InitiatingHeapOccupancyPercent=15` | Starts a concurrent GC cycle once the heap is 15% full, rather than waiting until it's nearly full — spreads GC work out instead of causing one big pause. |
| `-XX:G1MixedGCCountTarget=4` | Spreads old-generation cleanup across more, smaller mixed-GC cycles instead of fewer large ones. |
| `-XX:G1RSetUpdatingPauseTimePercent=5` | Caps how much of each pause is spent on remembered-set bookkeeping. |
| `-Dusing.aikars.flags=https://mcflags.emc.gs` / `-Dio.papermc.paper.suppress.sout.nags=true` | Informational/marker flags some server software checks for; harmless, safe to keep or remove. |

## How much RAM should I allocate?

- **Do not** allocate all of your machine's RAM to the JVM — leave headroom for the OS, disk cache (which speeds up chunk loading), and any other software (proxy, database, panel).
- A good starting point: allocate the JVM roughly **60-75%** of total system RAM, leaving the rest for the OS and disk cache.
- Set `-Xms` and `-Xmx` to the **same value** — this avoids heap-resize pauses.

| Total system RAM | Suggested `-Xms`/`-Xmx` |
|---|---|
| 4 GB | 2G – 3G |
| 8 GB | 5G – 6G |
| 16 GB | 10G – 12G |
| 32 GB | 20G – 24G |

These are starting points, not hard rules — actual needs depend on player count, world size, and plugins.

## Sizing tiers, explained

The core flag set (G1 tuning, tenuring, etc.) stays the same across all
sizes — only the heap size and a couple of region-related values need
adjusting. Below are ready-to-use examples for common allocations.

### 4 GB RAM — small survival / testing servers

Suitable for a handful of concurrent players, a small world, and few
plugins. Below this, the JVM itself plus a modern Paper/Spigot install
leaves very little headroom, so 4 GB is a practical floor rather than
somewhere to trim further.

```
java -Xms3G -Xmx3G \
  -XX:+UseG1GC \
  -XX:+ParallelRefProcEnabled \
  -XX:MaxGCPauseMillis=200 \
  -XX:+UnlockExperimentalVMOptions \
  -XX:+DisableExplicitGC \
  -XX:MaxTenuringThreshold=1 \
  -XX:G1NewSizePercent=30 \
  -XX:G1MaxNewSizePercent=40 \
  -XX:G1HeapRegionSize=4M \
  -XX:G1ReservePercent=20 \
  -XX:InitiatingHeapOccupancyPercent=15 \
  -XX:G1MixedGCCountTarget=4 \
  -XX:G1RSetUpdatingPauseTimePercent=5 \
  -Dio.papermc.paper.suppress.sout.nags=true \
  -jar server.jar --nogui
```

Note the smaller `G1HeapRegionSize` (4M instead of 8M) — region size
should scale down a little with smaller heaps to avoid too few total
regions.

### 8 GB RAM — small–medium survival servers

The most common allocation for a small community server with a modest
plugin count and moderate player counts. This is the size used in this
repo's [`start.sh`](start.sh) template.

```
java -Xms6G -Xmx6G \
  -XX:+UseG1GC \
  -XX:+ParallelRefProcEnabled \
  -XX:MaxGCPauseMillis=200 \
  -XX:+UnlockExperimentalVMOptions \
  -XX:+DisableExplicitGC \
  -XX:MaxTenuringThreshold=1 \
  -XX:G1NewSizePercent=30 \
  -XX:G1MaxNewSizePercent=40 \
  -XX:G1HeapRegionSize=8M \
  -XX:G1ReservePercent=20 \
  -XX:InitiatingHeapOccupancyPercent=15 \
  -XX:G1MixedGCCountTarget=4 \
  -XX:G1RSetUpdatingPauseTimePercent=5 \
  -Dio.papermc.paper.suppress.sout.nags=true \
  -jar server.jar --nogui
```

### 16 GB RAM — medium–large survival or small networks

Appropriate for a busier single server, or a small proxied network (a
Velocity proxy plus one or two backend servers sharing the box). If you're
running a proxy on the same machine, remember the proxy itself needs its
own modest heap — don't allocate this entire amount to a single backend
server if it isn't alone on the box.

```
java -Xms12G -Xmx12G \
  -XX:+UseG1GC \
  -XX:+ParallelRefProcEnabled \
  -XX:MaxGCPauseMillis=200 \
  -XX:+UnlockExperimentalVMOptions \
  -XX:+DisableExplicitGC \
  -XX:MaxTenuringThreshold=1 \
  -XX:G1NewSizePercent=30 \
  -XX:G1MaxNewSizePercent=40 \
  -XX:G1HeapRegionSize=8M \
  -XX:G1ReservePercent=20 \
  -XX:InitiatingHeapOccupancyPercent=15 \
  -XX:G1MixedGCCountTarget=4 \
  -XX:G1RSetUpdatingPauseTimePercent=5 \
  -Dio.papermc.paper.suppress.sout.nags=true \
  -jar server.jar --nogui
```

### 32 GB+ RAM — large networks or heavily-loaded servers

For large player counts, big worlds, or a network running several backend
servers on one box. At this size, consider a larger `G1HeapRegionSize`
(e.g. 16M) since larger heaps generally perform better with fewer, bigger
regions, and double-check that a single process actually benefits from
this much heap rather than splitting it across multiple smaller JVMs (one
per backend server) — several moderately-sized heaps often GC more
predictably than one very large one.

```
java -Xms24G -Xmx24G \
  -XX:+UseG1GC \
  -XX:+ParallelRefProcEnabled \
  -XX:MaxGCPauseMillis=200 \
  -XX:+UnlockExperimentalVMOptions \
  -XX:+DisableExplicitGC \
  -XX:MaxTenuringThreshold=1 \
  -XX:G1NewSizePercent=30 \
  -XX:G1MaxNewSizePercent=40 \
  -XX:G1HeapRegionSize=16M \
  -XX:G1ReservePercent=20 \
  -XX:InitiatingHeapOccupancyPercent=15 \
  -XX:G1MixedGCCountTarget=4 \
  -XX:G1RSetUpdatingPauseTimePercent=5 \
  -Dio.papermc.paper.suppress.sout.nags=true \
  -jar server.jar --nogui
```

See [`start.sh`](start.sh) for a ready-to-use script version with RAM as a variable.

## Which Java version?

Always use the Java version your server software's release notes recommend for your Minecraft version (this changes over time — check before deploying). Running an unsupported Java version is a common, avoidable cause of crashes and poor performance.

## Related guides

- [Linux optimization](../linux/linux-optimization.md) — file descriptors, swap, sysctl tuning that affects the JVM process.
- [Production checklist](../production/production-checklist.md) — confirming JVM flags before going live.
- [Troubleshooting](../troubleshooting/troubleshooting.md) — diagnosing high RAM/CPU usage.
