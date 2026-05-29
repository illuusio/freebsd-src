# Pkgconf Files Creation Scripts and Tools

This directory contains Lua applications designed to parse the `FreeBSD-apps.csv` file and create Pkgconfig files in subdirectories. The following steps have been tested with Flua and Lua 5.4.

## Creating an SBOM

To create a correct SPDX Lite 3.0 Software Bill of Materials (SBOM), follow these instructions:

1. **Install Necessary Tools:**
   Ensure you have development tools like Git, C-compiler, and autoconf installed on your system.

2. **Clone the Pkgconf Repository:**
   ```bash
   mkdir compile_pkgconfig
   cd compile_pkgconfig
   git clone https://github.com/pkgconf/pkgconf
   ```

3. **Build Pkgconf:**
   Inside the cloned `pkgconf` directory, run:
   ```bash
   ./autogen.sh
   ./configure
   make
   ```

4. **Link PC Files to SBOM Script:**
   Navigate back to your main directory and execute:
   ```bash
   cd ..
   ./share/sbom/link_pc_to_sbom.sh
   ```

5. **Generate SPDX Lite 3.0.1 Compatible SBOM:**
   Ensure the current directory is set correctly and run:
   ```bash
   cd sbom
   PKG_CONFIG_PATH=$(pwd) PKGCONFIG_ALLOW_INSECURE=yes ./pkgconf --spdx
   ```

## FreeBSD-apps.csv Generation Script

The following script can be used to generate `FreeBSD-apps.csv`; however, manual tuning may still be required.
```bash
#!/bin/bash

APPS=$(find crypto krb5 lib libexec sbin bin usr.bin usr.sbin -type f -name "*.[178]" | sort | grep -v "tests")
MAN_DIR="man_dir"

# Create pkgconfig from man pages. They are used to get
# short description
for app in ${APPS}; do
        echo -n "${app}|"
        CUR_APP=$(echo "${app}" | sed -E "s#.*/(.*)#\1#" | sed -e "s/\.man\$//" -e "s/\.[18]//")
        CUR_DIR=$(echo "${app}" | sed -E "s#^(.*)/.*#\1#")
        OUTPUT_DIR="${MAN_DIR}/${CUR_DIR}"
        mkdir -p "${OUTPUT_DIR}"
        echo -n "${CUR_APP}|${CUR_DIR}|"
        OUTPUT_MAN="${MAN_DIR}/${app}.man"
        man "${app}" | head -n 5 | tail -n +4 | sed -e "s/^[[:blank:]]*//" | sed -e "s/\t/ /g" -e "s/ -- /\|/" | tr -d "\n" >"${MAN_DIR}/${app}.man" >"${OUTPUT_MAN}"
        CONTENT=$(cat "${OUTPUT_MAN}" | sed -e "s/ [-—] /|/")
        echo "${CONTENT}"
done

# These are mostly libs that does not have man pages
APPS="lib/atf/libatf-c++/Makefile.depend \
lib/atf/libatf-c/Makefile.depend \
lib/clang/headers/Makefile.depend \
lib/clang/libclang/Makefile.depend \
lib/clang/liblldb/Makefile.depend \
lib/clang/libllvm/Makefile.depend \
lib/clang/libllvmminimal/Makefile.depend \
lib/csu/aarch64/Makefile.depend \
lib/csu/amd64/Makefile.depend \
lib/csu/arm/Makefile.depend \
lib/csu/i386/Makefile.depend \
lib/csu/powerpc64/Makefile.depend \
lib/csu/powerpc/Makefile.depend \
lib/csu/riscv/Makefile.depend \
libexec/atf/atf-check/Makefile.depend \
libexec/atf/atf-pytest-wrapper/Makefile.depend \
libexec/atf/atf-sh/Makefile.depend \
libexec/atrun/Makefile.depend \
libexec/blocklistd-helper/Makefile.depend \
libexec/bootpd/bootpgw/Makefile.depend \
libexec/bootpd/Makefile.depend \
libexec/dma/dmagent/Makefile.depend \
libexec/dma/dma-mbox-create/Makefile.depend \
libexec/hyperv/Makefile.depend \
libexec/mail.local/Makefile.depend \
libexec/nuageinit/Makefile.depend \
libexec/smrsh/Makefile.depend \
libexec/tcpd/Makefile.depend \
libexec/tftp-proxy/Makefile.depend \
libexec/ulog-helper/Makefile.depend \
lib/lib80211/Makefile.depend \
lib/lib9p/Makefile.depend \
lib/libalias/libalias/Makefile.depend \
lib/libalias/modules/dummy/Makefile.depend \
lib/libalias/modules/ftp/Makefile.depend \
lib/libalias/modules/irc/Makefile.depend \
lib/libalias/modules/nbt/Makefile.depend \
lib/libalias/modules/pptp/Makefile.depend \
lib/libalias/modules/skinny/Makefile.depend \
lib/libalias/modules/smedia/Makefile.depend \
lib/libarchive/Makefile.depend \
lib/libauditd/Makefile.depend \
lib/libbearssl/Makefile.depend \
lib/libbegemot/Makefile.depend \
lib/libbe/Makefile.depend \
lib/libblacklist/Makefile.depend \
lib/libblocklist/Makefile.depend \
lib/libblocksruntime/Makefile.depend \
lib/libbluetooth/Makefile.depend \
lib/libbsddialog/Makefile.depend \
lib/libbsdstat/Makefile.depend \
lib/libbsm/Makefile.depend \
lib/libbsnmp/libbsnmp/Makefile.depend \
lib/libbz2/Makefile.depend \
lib/libcalendar/Makefile.depend \
lib/libcam/Makefile.depend \
lib/libcapsicum/Makefile.depend \
lib/libcasper/libcasper/Makefile.depend \
lib/libcasper/services/cap_dns/Makefile.depend \
lib/libcasper/services/cap_fileargs/Makefile.depend \
lib/libcasper/services/cap_grp/Makefile.depend \
lib/libcasper/services/cap_netdb/Makefile.depend \
lib/libcasper/services/cap_net/Makefile.depend \
lib/libcasper/services/cap_pwd/Makefile.depend \
lib/libcasper/services/cap_sysctl/Makefile.depend \
lib/libcasper/services/cap_syslog/Makefile.depend \
lib/libcasper/services/Makefile.depend \
lib/libcbor/Makefile.depend \
lib/libc++experimental/Makefile.depend \
lib/libclang_rt/asan_cxx/Makefile.depend \
lib/libclang_rt/asan_dynamic/Makefile.depend \
lib/libclang_rt/asan/Makefile.depend \
lib/libclang_rt/asan-preinit/Makefile.depend \
lib/libclang_rt/profile/Makefile.depend \
lib/libclang_rt/safestack/Makefile.depend \
lib/libclang_rt/stats_client/Makefile.depend \
lib/libclang_rt/stats/Makefile.depend \
lib/libclang_rt/ubsan_standalone_cxx/Makefile.depend \
lib/libclang_rt/ubsan_standalone/Makefile.depend \
lib/libc++/Makefile.depend \
lib/libc/Makefile.depend \
lib/libc_nonshared/Makefile.depend \
lib/libcom_err/Makefile.depend \
lib/libcompat/Makefile.depend \
lib/libcompiler_rt/Makefile.depend \
lib/libcrypt/Makefile.depend \
lib/libcuse/Makefile.depend \
lib/libcxxrt/Makefile.depend \
lib/libdevctl/Makefile.depend \
lib/libdevdctl/Makefile.depend \
lib/libdevinfo/Makefile.depend \
lib/libdevstat/Makefile.depend \
lib/libdl/Makefile.depend \
lib/libdpv/Makefile.depend \
lib/libdwarf/Makefile.depend \
lib/libedit/Makefile.depend \
lib/libedit/readline/Makefile.depend \
lib/libefivar/Makefile.depend \
lib/libelf/Makefile.depend \
lib/libelftc/Makefile.depend \
lib/libevent1/Makefile.depend \
lib/libexecinfo/Makefile.depend \
lib/libexpat/Makefile.depend \
lib/libfetch/Makefile.depend \
lib/libfido2/Makefile.depend \
lib/libfigpar/Makefile.depend \
lib/libgcc_eh/Makefile.depend \
lib/libgcc_s/Makefile.depend \
lib/libgeom/Makefile.depend \
lib/libgpio/Makefile.depend \
lib/libgssapi/Makefile.depend \
lib/libiconv_modules/BIG5/Makefile.depend \
lib/libiconv_modules/DECHanyu/Makefile.depend \
lib/libiconv_modules/EUC/Makefile.depend \
lib/libiconv_modules/EUCTW/Makefile.depend \
lib/libiconv_modules/GBK2K/Makefile.depend \
lib/libiconv_modules/HZ/Makefile.depend \
lib/libiconv_modules/iconv_none/Makefile.depend \
lib/libiconv_modules/iconv_std/Makefile.depend \
lib/libiconv_modules/ISO2022/Makefile.depend \
lib/libiconv_modules/JOHAB/Makefile.depend \
lib/libiconv_modules/mapper_646/Makefile.depend \
lib/libiconv_modules/mapper_none/Makefile.depend \
lib/libiconv_modules/mapper_parallel/Makefile.depend \
lib/libiconv_modules/mapper_serial/Makefile.depend \
lib/libiconv_modules/mapper_std/Makefile.depend \
lib/libiconv_modules/mapper_zone/Makefile.depend \
lib/libiconv_modules/MSKanji/Makefile.depend \
lib/libiconv_modules/UES/Makefile.depend \
lib/libiconv_modules/UTF1632/Makefile.depend \
lib/libiconv_modules/UTF7/Makefile.depend \
lib/libiconv_modules/UTF8/Makefile.depend \
lib/libiconv_modules/VIQR/Makefile.depend \
lib/libiconv_modules/ZW/Makefile.depend \
lib/libifconfig/Makefile.depend \
lib/libipsec/Makefile.depend \
lib/libipt/Makefile.depend \
lib/libiscsiutil/Makefile.depend \
lib/libjail/Makefile.depend \
lib/libkiconv/Makefile.depend \
lib/libkldelf/Makefile.depend \
lib/libkvm/Makefile.depend \
lib/libldns/Makefile.depend \
lib/liblua/Makefile.depend \
lib/liblutok/Makefile.depend \
lib/liblzma/Makefile.depend \
lib/libmagic/Makefile.depend \
lib/libmd/Makefile.depend \
lib/libmemstat/Makefile.depend \
lib/libmilter/Makefile.depend \
lib/libmixer/Makefile.depend \
lib/libmp/Makefile.depend \
lib/libmt/Makefile.depend \
lib/libnetbsd/Makefile.depend \
lib/libnetgraph/Makefile.depend \
lib/libnetmap/Makefile.depend \
lib/libnv/Makefile.depend \
lib/libnvmf/Makefile.depend \
lib/libomp/Makefile.depend \
lib/libopenbsd/Makefile.depend \
lib/libopencsd/Makefile.depend \
lib/libpam/libpam/Makefile.depend \
lib/libpam/static_libpam/Makefile.depend \
lib/libpathconv/Makefile.depend \
lib/libpcap/Makefile.depend \
lib/libpe/Makefile.depend \
lib/libpfctl/Makefile.depend \
lib/libpjdlog/Makefile.depend \
lib/libpmc/Makefile.depend \
lib/libpmc/pmu-events/Makefile.depend \
lib/libpmcstat/Makefile.depend \
lib/libproc/Makefile.depend \
lib/libprocstat/Makefile.depend \
lib/libradius/Makefile.depend \
lib/libregex/Makefile.depend \
lib/librpcsec_gss/Makefile.depend \
lib/librpcsvc/Makefile.depend \
lib/librss/Makefile.depend \
lib/librtld_db/Makefile.depend \
lib/librt/Makefile.depend \
lib/libsbuf/Makefile.depend \
lib/libsdp/Makefile.depend \
lib/libsecureboot/Makefile.depend \
lib/libsmb/Makefile.depend \
lib/libsmdb/Makefile.depend \
lib/libsm/Makefile.depend \
lib/libsmutil/Makefile.depend \
lib/libsqlite3/Makefile.depend \
lib/libssp/Makefile.depend \
lib/libssp_nonshared/Makefile.depend \
lib/libstats/Makefile.depend \
lib/libstdbuf/Makefile.depend \
lib/libstdthreads/Makefile.depend \
lib/libsysdecode/Makefile.depend \
lib/libsys/Makefile.depend \
lib/libtacplus/Makefile.depend \
lib/libtelnet/Makefile.depend \
lib/libthread_db/Makefile.depend \
lib/libthr/Makefile.depend \
lib/libucl/Makefile.depend \
lib/libufs/Makefile.depend \
lib/libugidfw/Makefile.depend \
lib/libulog/Makefile.depend \
lib/libunbound/Makefile.depend \
lib/libusbhid/Makefile.depend \
lib/libusb/Makefile.depend \
lib/libutil/Makefile.depend \
lib/libveriexec/Makefile.depend \
lib/libvgl/Makefile.depend \
lib/libvmmapi/Makefile.depend \
lib/libwrap/Makefile.depend \
lib/libxo/encoder/csv/Makefile.depend \
lib/libxo/libxo/Makefile.depend \
lib/libxo/Makefile.depend \
lib/liby/Makefile.depend \
lib/libypclnt/Makefile.depend \
lib/libz/Makefile.depend \
lib/libzstd/Makefile.depend \
lib/msun/Makefile.depend \
lib/ncurses/form/Makefile.depend \
lib/ncurses/menu/Makefile.depend \
lib/ncurses/ncurses/Makefile.depend \
lib/ncurses/panel/Makefile.depend \
lib/ncurses/tinfo/Makefile.depend \
lib/ofed/complib/Makefile.depend \
lib/ofed/libcxgb4/Makefile.depend \
lib/ofed/libibcm/Makefile.depend \
lib/ofed/libibmad/Makefile.depend \
lib/ofed/libibnetdisc/Makefile.depend \
lib/ofed/libibverbs/Makefile.depend \
lib/ofed/libirdma/Makefile.depend \
lib/ofed/libmlx4/Makefile.depend \
lib/ofed/libmlx5/Makefile.depend \
lib/ofed/libopensm/Makefile.depend \
lib/ofed/librdmacm/Makefile.depend \
lib/ofed/libvendor/Makefile.depend"

for app in ${APPS}; do
        echo -n "${app}|"
        CUR_APP=$(echo "${app}" | sed -E "s#.*/(.*)#\1#" | sed -e "s/\.man\$//" -e "s/\.[18]//")
        CUR_DIR=$(echo "${app}" | sed -E "s#^(.*)/.*#\1#")
        CUR_APP=$(echo "${CUR_DIR}" | sed -E "s#.*/(.*)#\1#")
        echo -n "${CUR_APP}|${CUR_DIR}|${CUR_APP}|"
        echo "Library missing description"
done
```

Manual tuning is necessary to ensure everything is correct. This will be addressed in future updates.
```

# License extraction
Licenses were extracted with this shell script (Only from files that have SPDX header)
```
grep -r SPDX-License-Identifier sbin bin usr.* | grep -E "\.c|\.h" | grep -v "\.conf" | grep -v "SPDX-License-Identifier: FreeBSD-DOC and LicenseRef-FreeBSD-SBOM" | sed -e "s#: \* #|#" -e "s#:// #|#" -e "s#: \*\* #|#" -e "s#:  #|#" -e "s#SPDX-License-Identifier: ##"
```

# Using scancode-toolkit
```
scancode --info --copyright --license --license-score 95 --license-text --strip-root --ignore "test*" --ignore "*.1" --ignore "*.2" --ignore "*.3" --ignore "*.4" --ignore "*.5" --ignore "*.6" --ignore "*.7" --ignore "*.8" --ignore "Makefile*" --include "*.c" --include "*.h" --include "*.cc" --include "*.hh" --include "*.sh" --include "*.py" --include "*.pl" --include "*.S" --json-pp scancode_all_orig.json dirs
```

## Scancode JSON convert to usable
```
lua5.4 share/sbom/read_scancode_yaml.lua scancode/input.json scancode/output.yaml
```

## Update licenses with SED
This is example how to update licese information with SPDX-License-Identifier
```
sed -i -E "s#\/\* Copyright \(c\) (.*) The NetBSD Foundation, Inc.#/* SPDX-License-Identifier: BSD-2-Clause\n *\n * Copyright (c) \1 The NetBSD Foundation, Inc.#" *.c
```
