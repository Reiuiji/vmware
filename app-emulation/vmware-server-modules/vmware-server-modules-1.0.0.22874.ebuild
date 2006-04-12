# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

inherit linux-mod eutils versionator toolchain-funcs

PARENT_PN=${PN/-modules/}
MY_PV="e.x.p-$(get_version_component_range 4)"

DESCRIPTION="Modules for Vmware Server"
HOMEPAGE="http://www.vmware.com/"
SRC_URI="http://download3.vmware.com/software/vmserver/${PARENT_PN/vm/VM}-${MY_PV}.tar.gz"

S=${WORKDIR}

LICENSE="vmware"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
DEPEND=">=sys-apps/portage-2.0.54"

#CONFIG_CHECK="CRYPTO NET_RADIO SYSCTL"
#ERROR_CRYPTO="${P} requires Cryptographic API support (CONFIG_CRYPTO)."
#ERROR_NET_RADIO="${P} requires support for Wireless LAN drivers (non-hamradio) & Wireless Extensions (CONFIG_NET_RADIO)."
#ERROR_SYSCTL="${P} requires Sysctl support (CONFIG_SYSCTL)."
BUILD_TARGETS="auto-build"

pkg_setup() {
	linux-mod_pkg_setup

	MODULE_NAMES="vmmon(misc:${S}/vmmon-only)
				  vmnet(misc:${S}/vmnet-only)"
				  # vmppuser(misc:${S}/vmppuser-only)"

	# BUILD_PARAMS="KERNELPATH=${KV_OUT_DIR}"
}

src_unpack() {
	unpack ${A}

	for dir in vmmon vmnet; do
		cd ${S}
		# tar -xf ${DISTDIR}/$dir.tar
		unpack ./${PARENT_PN}-distrib/lib/modules/source/${dir}.tar
		cd ${S}/${dir}-only
		epatch ${FILESDIR}/${P}-makefile.patch
		if [ $(gcc-major-version) == "4" ]; then
			epatch ${FILESDIR}/${P}-makefile2.patch
		fi
		convert_to_m ${S}/${dir}-only/Makefile
	done

	rm -fr ${S}/${PARENT_PN}-distrib
}
