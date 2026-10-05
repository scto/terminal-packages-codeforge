TERMUX_PKG_HOMEPAGE=https://codeforge.com/
TERMUX_PKG_DESCRIPTION="Basic system tools for CodeForgeMobile"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@scto"
TERMUX_PKG_VERSION=0.10.0
TERMUX_PKG_SRCURL=https://github.com/scto/codeforge-tools/releases/download/v${TERMUX_PKG_VERSION}/codeforge-tools.tar.xz
TERMUX_PKG_SHA256=69bed7829c05497b976b7d41814111d03c11c3b7405410022b8967404fbe7d5c
TERMUX_PKG_PLATFORM_INDEPENDENT=true
TERMUX_PKG_ESSENTIAL=true

# Required by the tools included
TERMUX_PKG_DEPENDS="libcurl, jq, nano, wget"
TERMUX_PKG_RECOMMENDS="openjdk-17"

termux_step_make_install() {
    for script in codeforgesetup codeforgeenv; do
        install -Dm700 $TERMUX_PKG_SRCDIR/scripts/$script $TERMUX_PREFIX/bin/$script
    done
}