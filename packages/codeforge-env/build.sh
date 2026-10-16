TERMUX_PKG_HOMEPAGE=https://github.com/scto/CodeForgeMobile
TERMUX_PKG_DESCRIPTION="CodeForge environment manager: JDK, Android SDK, NDK and CMake setup (used by the CodeForge SDK manager)"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@scto"
# Version erhöhen, sobald sich codeforge-env.in ändert (Quelle: libs/terminal-engine/src/main/assets/codeforge-env
# im Repo CodeForgeMobile, Abgleich mit scripts/sync-codeforge-env-package.sh).
TERMUX_PKG_VERSION=1.0.0
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
}
