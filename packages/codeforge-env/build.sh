TERMUX_PKG_HOMEPAGE=https://github.com/scto/CodeForgeMobile
TERMUX_PKG_DESCRIPTION="CodeForge environment manager: JDK, Android SDK, NDK and CMake setup (used by the CodeForge SDK manager)"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@scto"
# Version erhöhen, sobald sich codeforge-env.in ändert (Quelle: libs/terminal-engine/src/main/assets/codeforge-env
# im Repo CodeForgeMobile, Abgleich mit scripts/sync-codeforge-env-package.sh).
TERMUX_PKG_VERSION=1.0.3
TERMUX_PKG_SKIP_SRC_EXTRACT=true
TERMUX_PKG_PLATFORM_INDEPENDENT=true
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_DEPENDS="bash, coreutils, curl, gawk, grep, jq, sed, tar, unzip, xz-utils, openjdk-17 | openjdk-21"

termux_step_make_install() {
	# Gleiche Ersetzung wie ScriptInstaller.render(template, repoUrl = null) in der App; @CODEFORGE_SDK_REPO@
	# bleibt bewusst stehen, damit die App die Datei als identisch erkennt und sie nicht überschreibt.
	mkdir -p "$TERMUX_PREFIX/bin"
	sed \
		-e "s|@TERMUX_PREFIX@|${TERMUX_PREFIX}|g" \
		-e "s|@TERMUX_HOME@|${TERMUX_ANDROID_HOME}|g" \
		"$TERMUX_PKG_BUILDER_DIR/codeforge-env.in" > "$TERMUX_PREFIX/bin/codeforge-env"
	chmod 755 "$TERMUX_PREFIX/bin/codeforge-env"

	# $PREFIX/tmp mit ins Paket: JVM/Gradle brechen sonst mit
	# "java.io.tmpdir is set to a directory that doesn't exist" ab. Leere Verzeichnisse
	# werden von dpkg angelegt (und beim Entfernen nur gelöscht, wenn sie leer sind).
	mkdir -p "$TERMUX_PREFIX/tmp"
}

termux_step_create_debscripts() {
	# Absicherung für Bootstrap-Archive/Installer, die leere Verzeichnisse verlieren.
	cat > ./postinst <<-POSTINST_EOF
		#!$TERMUX_PREFIX/bin/sh
		mkdir -p "$TERMUX_PREFIX/tmp"
		chmod 1777 "$TERMUX_PREFIX/tmp" 2>/dev/null || chmod 700 "$TERMUX_PREFIX/tmp" 2>/dev/null || true
		exit 0
	POSTINST_EOF
	chmod 755 ./postinst
}
