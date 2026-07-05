#!/usr/bin/env bash
# =========================================================================
#  MinecraftConfigurator — start.sh
#  Ready-to-use startup script template. Set RAM below, then run.
# =========================================================================

# --- EDIT THIS: set to the same value, sized per jvm/README.md ---
RAM="8G"

# --- EDIT THIS: point at your server jar ---
SERVER_JAR="server.jar"

java -Xms${RAM} -Xmx${RAM} \
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
  -jar "${SERVER_JAR}" --nogui
