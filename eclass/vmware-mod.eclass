# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: vmware-modules-101-r3.ebuild 48 2006-05-28 16:54:26Z ikelos $


# Ensure vmware comes before linux-mod since we want linux-mod's pkg_preinst and
# pkg_postinst, along with our own pkg_setup, src_unpack and src_compile
inherit eutils vmware linux-mod

PARENT_PN=${PN/-modules/}

PATCHSET="1"
DESCRIPTION="Modules for Vmware Programs"
HOMEPAGE="http://www.vmware.com/"
SRC_URI="http://ftp.cvut.cz/vmware/${ANY_ANY}.tar.gz"
LICENSE="vmware"
SLOT="0"
IUSE=""
# Provide vaguely sensible defaults
VMWARE_VER="VME_V55"

DEPEND=">=sys-apps/portage-2.0.54"

S=${WORKDIR}

# We needn't restrict this since it was only required to read
# /etc/vmware/locations to determine the version (which is now fixed by
# VMWARE_VER)
# RESTRICT="userpriv"

EXPORT_FUNCTIONS pkg_setup src_unpack src_install 

# Must define VMWARE_VER to make, otherwise it'll try and run getversion.pl,
# which we've removed to ensure we never use it
BUILD_TARGETS="auto-build VMWARE_VER=${VMWARE_VER}"

vmware-mod_pkg_setup() {
	linux-mod_pkg_setup

	MODULE_NAMES="vmmon(misc:${S}/vmmon-only)
				  vmnet(misc:${S}/vmnet-only)"
}

vmware-mod_src_unpack() {
	unpack ${A}

	for dir in vmmon vmnet; do
		cd ${S}
		unpack ./${ANY_ANY}/${dir}.tar
		cd ${S}/${dir}-only
		# Ensure it's not used
		# rm getversion.pl
		EPATCH_SUFFIX="patch"
		epatch ${FILESDIR}/patches
		convert_to_m ${S}/${dir}-only/Makefile
	done
}

vmware-mod_src_install() {
	# this adds udev rules for vmmon*
	dodir /etc/udev/rules.d
	echo 'KERNEL=="vmmon*", GROUP="'$VMWARE_GROUP'" MODE=660' > ${D}/etc/udev/rules.d/60-vmware.rules || die
	
	linux-mod_src_install
}


# Current VMWARE product mappings
# 'VME_TOT'		= .0
# 'VME_GSX1'	= .1
# 'VME_GSX2'	= .2
# 'VME_GSX251'	= .3
# 'VME_GSX25'	= .4
# 'VME_GSX32'	= .5
# 'VME_V3'		= .6
# 'VME_V32'		= .7
# 'VME_V321'	= .8
# 'VME_V4'		= .9
# 'VME_V45'		= .10
# 'VME_V452'	= .11
# 'VME_V5'		= .12
# 'VME_V55'		= .13
# 'VME_S1B1'	= .14
# 'VME_S1??'	= .15
