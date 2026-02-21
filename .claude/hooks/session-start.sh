#!/bin/bash
set -euo pipefail

# Only run in remote Claude Code environments
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# ── 1. Swift ──────────────────────────────────────────────────────────────────
if command -v swift &> /dev/null; then
  echo "Swift $(swift --version 2>&1 | head -1) already installed"
else
  # swiftlang 6.0.3 lives in Ubuntu noble universe. The package index in remote
  # sessions may not include universe yet, so download the .deb trio directly.
  echo "Installing Swift 6.0.3..."
  UBUNTU_POOL="http://archive.ubuntu.com/ubuntu/pool"
  curl -fsSL "${UBUNTU_POOL}/main/libx/libxml2/libxml2-16_2.14.5+dfsg-0.2ubuntu0.1_amd64.deb" \
       -o /tmp/libxml2-16.deb
  curl -fsSL "${UBUNTU_POOL}/universe/s/swiftlang/libswiftlang_6.0.3-2build1_amd64.deb" \
       -o /tmp/libswiftlang.deb
  curl -fsSL "${UBUNTU_POOL}/universe/s/swiftlang/swiftlang_6.0.3-2build1_amd64.deb" \
       -o /tmp/swiftlang.deb
  dpkg -i /tmp/libxml2-16.deb /tmp/libswiftlang.deb /tmp/swiftlang.deb
  rm -f /tmp/libxml2-16.deb /tmp/libswiftlang.deb /tmp/swiftlang.deb
  echo "Done: $(swift --version 2>&1 | head -1)"
fi

# ── 2. SQLite with SQLITE_ENABLE_SNAPSHOT (required by GRDB) ─────────────────
# Ubuntu's libsqlite3 is not compiled with SQLITE_ENABLE_SNAPSHOT.
# We rebuild it from the sqlite.org amalgamation and replace the system copies.
# Note: the library must go into /usr/lib/x86_64-linux-gnu/ — SPM's linker
# searches that path before /usr/local/lib/, so writing only to /usr/local/lib/
# would silently link the snapshot-less system library instead.
CUSTOM_SQLITE_MARKER="/usr/local/lib/libsqlite3-snapshot.marker"
if [ ! -f "$CUSTOM_SQLITE_MARKER" ]; then
  echo "Building SQLite with SQLITE_ENABLE_SNAPSHOT support..."
  SQLITE_VER_NUM="3450100"   # 3.45.1 — matches Ubuntu 24.04 package
  SQLITE_ZIP="sqlite-amalgamation-${SQLITE_VER_NUM}.zip"
  curl -fSL "https://www.sqlite.org/2024/${SQLITE_ZIP}" -o "/tmp/${SQLITE_ZIP}"
  unzip -q "/tmp/${SQLITE_ZIP}" -d /tmp/sqlite-src
  cd "/tmp/sqlite-src/sqlite-amalgamation-${SQLITE_VER_NUM}"

  gcc -O2 -DSQLITE_ENABLE_SNAPSHOT -DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_RTREE \
      -fPIC -shared sqlite3.c -o libsqlite3.so.0.8.6
  gcc -O2 -DSQLITE_ENABLE_SNAPSHOT -DSQLITE_ENABLE_FTS5 -DSQLITE_ENABLE_RTREE \
      -fPIC -c sqlite3.c -o sqlite3.o
  ar rcs libsqlite3.a sqlite3.o

  for DIR in /usr/lib/x86_64-linux-gnu /lib/x86_64-linux-gnu; do
    cp libsqlite3.so.0.8.6 "$DIR/libsqlite3.so.0.8.6"
    cp libsqlite3.a         "$DIR/libsqlite3.a"
  done
  cp sqlite3.h /usr/local/include/sqlite3.h
  ldconfig

  touch "$CUSTOM_SQLITE_MARKER"
  cd / && rm -rf /tmp/sqlite-src "/tmp/${SQLITE_ZIP}"
  echo "Custom SQLite built and installed"
else
  echo "Custom SQLite already installed"
fi

# ── 3. Resolve Swift package dependencies ─────────────────────────────────────
echo "Resolving Swift package dependencies..."
cd "${CLAUDE_PROJECT_DIR}/GymTrackKit"
swift package resolve

echo "Session start hook complete."
