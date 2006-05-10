# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

# Unlike many other binary packages the user doesn't need to agree to a licence
# to download VMWare. The agreeing to a licence is part of the configure step
# which the user must run manually.

inherit vmware eutils versionator

VMWARE_VME="VME_S1B1"

MY_PN="VMware-server"
MY_PV="e.x.p-$(get_version_component_range 4)"
NP="${MY_PN}-${MY_PV}"
S="${WORKDIR}/vmware-server-distrib"

DESCRIPTION="VMware Server for Linux"
HOMEPAGE="http://www.vmware.com/"
SRC_URI="http://download3.vmware.com/software/vmserver/${NP}.tar.gz
		 http://dev.gentoo.org/~ikelos/devoverlay-distfiles/${P}-rpath-corrected-libs.tar.bz2"

LICENSE="vmware"
IUSE=""
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
RESTRICT="nostrip"

DEPEND=">=sys-libs/glibc-2.3.5
		>=dev-lang/perl-5
		sys-apps/pciutils
		sys-apps/findutils
		virtual/os-headers"
# vmware-server should not use virtual/libc as this is a 
# precompiled binary package thats linked to glibc.
RDEPEND=">=sys-libs/glibc-2.3.5
	amd64? ( app-emulation/emul-linux-x86-baselibs
	         app-emulation/emul-linux-x86-gtklibs 
		   )
	!amd64 ( || ( ( x11-libs/libX11
			x11-libs/libXtst
			x11-libs/libXext
			x11-libs/libXt 
			x11-libs/libICE
			x11-libs/libSM
			x11-libs/libXrender
		      )
		      ( virtual/x11 
			virtual/xft
		      )
		    )
	       )
	>=dev-lang/perl-5
	!app-emulation/vmware-player
	!app-emulation/vmware-workstation
	sys-apps/pciutils
	sys-apps/xinetd
	>=sys-apps/baselayout-1.11.14"
PDEPEND=">=app-emulation/vmware-modules-101"

dir=/opt/vmware/server
Ddir=${D}/${dir}
VMWARE_GROUP=${VMWARE_GROUP:-vmware}

EPATCH_SOURCE=${FILESDIR}/${P}

pkg_setup() {
	# This is due to both bugs #104480 and #106170
	enewgroup "${VMWARE_GROUP}"

	vmware_test_module_build
}

src_unpack() {
	unpack ${A}
	cd ${S}
	
	epatch ${FILESDIR}/${PV}

	# patch the vmware /etc/pam.d file to ensure that only 
	# vmware group members can log in
	cp ${FILESDIR}/vmware-authd ${S}/etc/pam.d/vmware-authd
}

src_install() {
	dodir ${dir}/bin
	cp -pPR ${S}/bin/* ${Ddir}/bin

	dodir ${dir}/sbin
	cp -pPR ${S}/sbin/* ${Ddir}/sbin

	dodir ${dir}/lib
	cp -dr ${S}/lib/* ${Ddir}/lib

	# Since with Gentoo we compile everthing it doesn't make sense to keep
	# the precompiled modules arround. Saves about 4 megs of disk space too.
	rm -rf ${Ddir}/lib/modules/binary
	# We also don't need to keep the icons around
	rm -rf ${Ddir}/lib/share/icons
	# We set vmware-vmx and vmware-ping suid
	chmod u+s ${Ddir}/bin/vmware-ping
	# chmod u+s ${Ddir}/lib/bin/vmware-vmx
	# chmod u+s ${Ddir}/sbin/vmware-authd

	dodoc doc/* || die "dodoc"
	# Fix for bug #91191
	dodir ${dir}/doc
	insinto ${dir}/doc
	doins doc/EULA || die "copying EULA"

	doman ${S}/man/man1/vmware.1.gz || die "doman"

	# vmware service loader
	newinitd ${FILESDIR}/vmware.rc vmware || die "newinitd"

	# vmware enviroment
	doenvd ${FILESDIR}/90vmware-server || die "doenvd"

	# Fix the amd64 emulation pam stuff
	use amd64 && dosed ":pam_:/emul/linux/x86/lib/security/pam_:" /etc/pam.d/vmware-authd

	dodir /etc/vmware/
	cp -pPR etc/* ${D}/etc/vmware/
	echo "${VMWARE_GROUP}" > ${D}/etc/vmware/vmwaregroup

	dodir /etc/vmware/init.d
	dodir /etc/vmware/init.d/rc0.d
	dodir /etc/vmware/init.d/rc1.d
	dodir /etc/vmware/init.d/rc2.d
	dodir /etc/vmware/init.d/rc3.d
	dodir /etc/vmware/init.d/rc4.d
	dodir /etc/vmware/init.d/rc5.d
	dodir /etc/vmware/init.d/rc6.d
	dosym /etc/init.d/xinetd /etc/vmware/init.d
	cp -pPR installer/services.sh ${D}/etc/vmware/init.d/vmware || die

	# This is to fix a problem where if someone merges vmware and then
	# before configuring vmware they upgrade or re-merge the vmware
	# package which would rmdir the /etc/vmware/init.d/rc?.d directories.
	keepdir /etc/vmware/init.d/rc{0,1,2,3,4,5,6}.d

	#insinto ${dir}/lib/icon
	#doins ${S}/lib/share/icons/48x48/apps/${PN}.png || die
	#doicon ${S}/lib/share/icons/48x48/apps/${PN}.png || die
	insinto /usr/share/mime/packages
	doins ${FILESDIR}/vmware.xml

	# make_desktop_entry vmware "VMWare Server" ${PN}.png

	dodir /usr/bin
	dosym ${dir}/bin/vmware /usr/bin/vmware

	# this removes the user/group warnings
	chown -R root:0 ${D} || die

	dodir /etc/vmware
	# this makes the vmware-vmx executable only executable by vmware group
	fowners root:${VMWARE_GROUP} ${dir}/sbin/vmware-authd ${dir}/lib/bin{,-debug}/vmware-vmx /etc/vmware \
		|| die "Changing permissions"
	fperms 4750 ${dir}/lib/bin{,-debug}/vmware-vmx ${dir}/sbin/vmware-authd || die
	fperms 770 /etc/vmware || die

	# this adds udev rules for vmmon*
	dodir /etc/udev/rules.d
	echo 'KERNEL=="vmmon*", GROUP="'${VMWARE_GROUP}'" MODE=660' > \
		${D}/etc/udev/rules.d/60-vmware.rules || die

	# Questions:
	einfo "Adding answers to /etc/vmware/locations"
	locations="${D}/etc/vmware/locations"
	echo "answer BINDIR ${dir}/bin" >> ${locations}
	echo "answer SBINDIR ${dir}/sbin" >> ${locations}
	echo "answer LIBDIR ${dir}/lib" >> ${locations}
	echo "answer MANDIR ${dir}/man" >> ${locations}
	echo "answer DOCDIR ${dir}/doc" >> ${locations}
	echo "answer RUN_CONFIGURATOR no" >> ${locations}
	echo "answer INITDIR /etc/vmware/init.d" >> ${locations}
	echo "answer INITSCRIPTSDIR /etc/vmware/init.d" >> ${locations}
}

pkg_preinst() {
	# This must be done after the install to get the mtimes on each file
	# right. This perl snippet gets the /etc/vmware/locations file code:
	# perl -e "@a = stat('bin/vmware'); print \$a[9]"
	# The above perl line and the find line below output the same thing.
	# I would think the find line is faster to execute.
	# find /opt/vmware/workstation/bin/vmware -printf %T@

	#Note: it's a bit weird to use ${D} in a preinst script but it should work
	#(drobbins, 1 Feb 2002)

	einfo "Generating /etc/vmware/locations file."
	d=`echo ${D} | wc -c`
	for x in `find ${Ddir} ${D}/etc/vmware` ; do
		x="`echo ${x} | cut -c ${d}-`"
		if [ -d ${D}/${x} ] ; then
			echo "directory ${x}" >> ${D}/etc/vmware/locations
		else
			echo -n "file ${x}" >> ${D}/etc/vmware/locations
			if [ "${x}" == "/etc/vmware/locations" ] ; then
				echo "" >> ${D}/etc/vmware/locations
			elif [ "${x}" == "/etc/vmware/not_configured" ] ; then
				echo "" >> ${D}/etc/vmware/locations
			else
				echo -n " " >> ${D}/etc/vmware/locations
				#perl -e "@a = stat('${D}${x}'); print \$a[9]" >> ${D}/etc/vmware/locations
				find ${D}${x} -printf %T@ >> ${D}/etc/vmware/locations
				echo "" >> ${D}/etc/vmware/locations
			fi
		fi
	done
}

pkg_config() {
	einfo "Running ${ROOT}${dir}/bin/vmware-config.pl"
	${ROOT}${dir}/bin/vmware-config.pl
}

pkg_postinst() {
	update-mime-database ${ROOT}/usr/share/mime
	[ -d ${ROOT}/etc/vmware ] && chown -R root:${VMWARE_GROUP} ${ROOT}/etc/vmware

	# This is to fix the problem where the not_configured file doesn't get
	# removed when the configuration is run. This doesn't remove the file
	# It just tells the vmware-config.pl script it can delete it.
	einfo "Updating /etc/vmware/locations"
	for x in "${ROOT}/etc/vmware/._cfg????_locations" ; do
		if [ -f $x ] ; then
			cat $x >> "${ROOT}/etc/vmware/locations"
			rm $x
		fi
	done

	einfo
	einfo "You need to run ${dir}/bin/vmware-config.pl to complete the install."
	einfo
	einfo "For VMware Add-Ons just visit"
	einfo "http://www.vmware.com/download/downloadaddons.html"
	einfo
	einfo "Remember by default xinetd only allows connections from localhost"
	einfo "To allow external users access to vmware-server you must edit"
	einfo "    /etc/xinetd.d/vmware-authd"
	einfo "and specify a new 'only_from' line"
	einfo
	einfo "Also note that when you reboot you should run:"
	einfo "    /etc/init.d/vmware start"
	einfo "before trying to run vmware.  Or you could just add"
	einfo "it to the default run level:"
	einfo "rc-update add vmware default"
	echo
	ewarn "Remember, in order to connect to vmware-server, you have to"
	ewarn "be in the '${VMWARE_GROUP}' group."
	echo
	ewarn "VMWare allows for the potential of overwriting files as root.  Only"
	ewarn "give VMWare access to trusted individuals."
	echo
	ewarn "VMWare also has issues when running on a JFS filesystem.  For more"
	ewarn "information see http://bugs.gentoo.org/show_bug.cgi?id=122500#c94"
	#ewarn "For users of glibc-2.3.x, vmware-nat support is *still* broken on 2.6.x"
}

pkg_postrm() {
	einfo
	einfo "To remove all traces of vmware you will need to remove the files"
	einfo "in /etc/vmware/, /etc/init.d/vmware, /lib/modules/*/misc/vm*.{ko,o},"
	einfo "and .vmware/ in each users home directory. Don't forget to rmmod the"
	einfo "vm* modules, either."
	einfo
}
