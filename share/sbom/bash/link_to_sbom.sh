#/bin/bash

PC_FILES=$(find lib libexec bin sbin usr.bin usr.sbin -name *.pc)

echo "Name: FreeBSD-src" > sbom/FreeBSD.pc
echo "Description: Metapackage for FreeBSD src" >> sbom/FreeBSD.pc
echo "URL: https://freebsd.org" >> sbom/FreeBSD.pc
echo "Version: 15.0" >> sbom/FreeBSD.pc
echo "License: FreeBSD-DOC and LicenseRef-FreeBSD-SBOM" >> sbom/FreeBSD.pc
echo "Source: https://cgit.freebsd.org/src/tree/?h=stable/15" >> sbom/FreeBSD.pc
echo -n "Requires: " >> sbom/FreeBSD.pc

cd sbom

for orig_file in ${PC_FILES}
do
   BASENAME_PC_FILE=$(basename ${orig_file})
   REQUIRES_NAME=$(echo ${BASENAME_PC_FILE} | sed -e "s/\.pc\$//")
   echo ${BASENAME_PC_FILE}
   SBOM_NAME="${BASENAME_PC_FILE}"

   if [ -f "${SBOM_NAME}" ]
   then
       rm "${SBOM_NAME}"
   fi

   ln -sf "../${orig_file}" "${SBOM_NAME}"
   echo "${REQUIRES_NAME} \\" >> FreeBSD.pc
done

cd ..
