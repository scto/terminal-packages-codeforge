TERMUX_PKG_HOMEPAGE=https://www.rust-lang.org/
TERMUX_PKG_DESCRIPTION="Rust source code files"
TERMUX_PKG_LICENSE="MIT, Apache-2.0"
TERMUX_PKG_LICENSE_FILE="LICENSE-MIT, LICENSE-APACHE"
TERMUX_PKG_MAINTAINER="@termux"
# Muss immer der Version von packages/rust entsprechen (Quelle: dasselbe rustc-Quellarchiv).
TERMUX_PKG_VERSION="1.99.0"
TERMUX_PKG_SRCURL="https://static.rust-lang.org/dist/rustc-${TERMUX_PKG_VERSION}-src.tar.xz"
TERMUX_PKG_SHA256=cc41916a8c84f5d9ec4f55561b44e39f43b647b133f8a6f51be9ea13c83f7036
TERMUX_PKG_PLATFORM_INDEPENDENT=true
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_BREAKS="rust (<< ${TERMUX_PKG_VERSION})"
TERMUX_PKG_REPLACES="rust (<< ${TERMUX_PKG_VERSION})"

# CodeForge: Eigenständiges Paket statt Unterpaket von `rust`. Nur der Quelltext der Standardbibliothek wird
# kopiert (wie `x.py dist rust-src`); der Build von rustc/LLVM (viele Stunden) entfällt komplett.
termux_step_configure() {
	:
}

termux_step_make() {
	:
}

termux_step_make_install() {
	local dst="${TERMUX_PREFIX}/lib/rustlib/src/rust"
	rm -rf "${dst}"
	mkdir -p "${dst}/src/llvm-project"
	cp -a library "${dst}/library"
	cp -a src/llvm-project/libunwind "${dst}/src/llvm-project/libunwind"
	# Wie bootstrap/dist.rs (Src): unnötige bzw. symlinkhaltige Teile weglassen.
	rm -rf "${dst}/library/backtrace/crates" \
		"${dst}/library/stdarch/crates/stdarch-verify" \
		"${dst}/library/stdarch/crates/intrinsic-test"
	rm -f "${dst}/library/stdarch/Cargo.toml"
	# Von rust-analyzer und build-std erwartet: Cargo.lock der Standardbibliothek
	[ -f library/Cargo.lock ] || cp Cargo.lock "${dst}/library/Cargo.lock" 2>/dev/null || true
	# Build-Artefakte/Test-Reste sind im Quellarchiv nicht enthalten; sicherheitshalber entfernen.
	find "${dst}" -type d \( -name target -o -name .git \) -prune -exec rm -rf {} + 2>/dev/null || true
}
