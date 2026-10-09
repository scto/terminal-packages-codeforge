#!/usr/bin/env bash
# fix-fork.sh – repariert den terminal-packages-codeforge-Fork (idempotent, ohne git apply).
#
# Behebt:
#   1. URLs, die ein globales `sed s/com.termux/com.codeforge/` zerstört hat
#      (github.com/termux/<repo> -> github.com/termux/<repo>)
#   2. den glibc-Pfad in termux_step_setup_cgct_environment.sh (bleibt com.termux)
#   3. test-runner.sh-Shebang und die Meldung in build-bootstraps.sh
#   4. verlorene Symlinks (kleine Textdateien, deren Inhalt der Link-Pfad ist)
#
# Aufruf (aus dem Fork-Root oder mit Pfad):
#   bash fix-fork.sh [PFAD_ZUM_FORK]     # Standard: aktuelles Verzeichnis
# Danach prüfen und committen:
#   git status --short | head; git add -A; git commit -m "Fix: URLs, glibc-Pfad, Symlinks"
#
# Hinweis: build_codeforge_repo.sh macht dasselbe bei jedem Lauf selbst; dieses Script ist nur
# nötig, wenn du die Reparatur dauerhaft im Fork committen willst.
set -euo pipefail

APP_PACKAGE="${APP_PACKAGE:-com.codeforge.app}"
ROOT="$(cd "${1:-.}" && pwd)"

die() { echo "FEHLER: $*" >&2; exit 1; }

[ -d "${ROOT}/.git" ] || die "${ROOT} ist kein Git-Repository (Fork-Root angeben)."
[ -f "${ROOT}/build-package.sh" ] && [ -d "${ROOT}/scripts" ] || die "${ROOT} sieht nicht wie der Fork aus (build-package.sh/scripts fehlen)."
command -v python3 >/dev/null || die "python3 fehlt."

# 1. Beschädigte URLs
changed=0
while IFS= read -r f; do
    sed -i -e 's#github\.com\.codeforge\.app/#github.com/termux/#g' \
           -e 's#github\.com\.codeforge/#github.com/termux/#g' "${f}"
    changed=$((changed + 1))
done < <(grep -rlIE 'github\.com\.codeforge(\.app)?/' --exclude-dir=.git "${ROOT}" || true)

# 2. glibc-Pfad innerhalb des offiziellen glibc-Pakets: bleibt com.termux
cgct="${ROOT}/scripts/build/termux_step_setup_cgct_environment.sh"
if [ -f "${cgct}" ]; then
    hit="$(grep -l 'data/data/com\.codeforge/files/usr/glibc' "${cgct}" || true)"
    if [ -n "${hit}" ]; then
        sed -i 's#data/data/com\.codeforge/files/usr/glibc#data/data/com.termux/files/usr/glibc#' "${cgct}"
        changed=$((changed + 1))
    fi
fi

# 3. test-runner.sh und build-bootstraps.sh
tr_file="${ROOT}/scripts/test-runner.sh"
if [ -f "${tr_file}" ]; then
    first="$(head -n1 "${tr_file}")"
    case "${first}" in
        *'/data/data/com.codeforge/files'*)
            sed -i "1s#/data/data/com\.codeforge/files#/data/data/${APP_PACKAGE}/files#" "${tr_file}"
            changed=$((changed + 1)) ;;
    esac
fi
bb="${ROOT}/scripts/build-bootstraps.sh"
[ -f "${bb}" ] && sed -i "s#It defaults to 'com\.codeforge'\.#It defaults to '${APP_PACKAGE}'.#" "${bb}"

echo "Textreparatur: ${changed} Datei(en) angepasst."
bad="$(grep -rlIE 'github\.com\.codeforge' --exclude-dir=.git "${ROOT}" || true)"
[ -z "${bad}" ] || die "Beschädigte Verweise bleiben: ${bad}"

# 4. Symlinks wiederherstellen (nur eindeutige Fälle: <=150 Byte, eine Zeile, reiner Pfad, Ziel existiert)
python3 -I - "${ROOT}" <<'PY'
import os, re, subprocess, sys
root = sys.argv[1]
out = subprocess.run(["git", "-C", root, "ls-files", "-s", "-z"], capture_output=True, check=True).stdout.decode("utf8", "surrogateescape")
restored = 0
for entry in out.split("\0"):
    if not entry:
        continue
    meta, path = entry.split("\t", 1)
    if meta.split()[0] != "100644":
        continue
    p = os.path.join(root, path)
    if os.path.islink(p) or not os.path.isfile(p) or os.path.getsize(p) > 150:
        continue
    try:
        text = open(p, "rb").read().decode("utf8")
    except UnicodeDecodeError:
        continue
    target = text.rstrip("\r\n")
    if not target or "\n" in target or not re.fullmatch(r"[A-Za-z0-9._/+@~-]+/?", target):
        continue
    resolved = os.path.normpath(os.path.join(os.path.dirname(p), target))
    if not os.path.exists(resolved) or os.path.abspath(resolved) == os.path.abspath(p):
        continue
    os.remove(p)
    os.symlink(target, p)
    restored += 1
print(f"Symlinks wiederhergestellt: {restored}")
PY

[ -d "${ROOT}/packages/procps/hsearch" ] || die "packages/procps/hsearch ist kein Verzeichnis – Symlink-Reparatur unvollständig."
echo "Fertig. Prüfen: git status --short | head; dann git add -A && git commit."

