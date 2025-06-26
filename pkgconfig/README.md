# Technical Guide: C SBOMs with Pkg-config Files

This directory contains a draft implementation (currently WIP) of C Software Bill of Materials (SBOMs), following the approach outlined in [C SBOMs and how pkgconf can solve this 
problem](https://ariadne.space/2025/02/08/c-sboms-and-how-pkgconf.html). The files here are primarily `pkg-config` files, which were originally introduced to simplify linking of C applications. While 
these `.pc` files are not meant for actual application linking, they serve as a means to generate SBOMs.

## Pkg-config Files

The pkg-config files in this repository have been tailored specifically for *FreeBSD* sources and are prefixed with `FreeBSD-` to ensure clarity about their intended use. These files incorporate crucial 
information such as upstream version (if applicable), license, URL, LicenseFile link, and Source link. In an ideal scenario, the `.pc` files should include:

 * **Name:** The package name
 *  **Description:** A brief description of the package
 * **URL:** The official website or repository URL
 * **Version:** The version number of the package
 * **License:** The software license type
 * **LicenseFile:** Link to the actual license file (if available)
 * **Source:** URL pointing to the upstream source code

Please note that `LicenseFile` and `Source` are not currently part of the standard pkg-config specification but may be added in future iterations if found useful.

## File Structure Example

A typical `.pc` file should look like this:

```plaintext
# SPDX-License-Identifier: BSD-2-Clause
# Copyright (c) 2025 The FreeBSD Foundation
# This software was developed by
# under sponsorship from the FreeBSD Foundation.
Name: package
Description: Some package
URL: https://freebsd.org
Version: 14.3
License: BSD-2-Clause
LicenseFile: https://spdx.org/licenses/preview/BSD-2-Clause-FreeBSD.html
Source: https://cgit.freebsd.org/src/tree/
```

## Using the Pkg-config Files

Examples to use these `.pc` files with `pkgconf`:

 * **Set Environment Path:**
   Ensure that the path to your pkg-config files is included in the `PKG_CONFIG_PATH`.
 * **List All Available Packages:**
   Run the following command to list all available packages along with their names and descriptions:
   ```bash
   PKG_CONFIG_PATH=/path/to/pkgconfig pkgconf --env-only --list-all
   ```
 * **Simulate Dependency Tree:**
   To generate a detailed dependency tree for a specific package (e.g., `FreeBSD-src`), use the following command:
   ```bash
   PKG_CONFIG_PATH=/path/to/pkgconfig pkgconf --env-only --simulate FreeBSD-src
   ```
 * **Generate SVG Diagram of Dependencies:**
   Create an SVG diagram representing dependencies with:
   ```bash
   PKG_CONFIG_PATH=/path/to/pkgconfig pkgconf --env-only --digraph FreeBSD-src | dot -Tsvg > output.svg
   ```
   This command will produce a more sophisticated and visually appealing SVG dependency diagram.


## REUSE SOFTWARE TOML

For example, making of Zlib [REUSE TOML](https://reuse.software/) file with scancode-toolkit command would be:
```
scancode -clpeui -n 16 --include "*.c" --include="*.h" --custom-output pkgconfig/FreeBSD-libc.toml --custom-template pkgconfig/tmpl/template.toml lib/libc
scancode -clpeui -n 16 --include "*.c" --include="*.h" --custom-output pkgconfig/FreeBSD-mkuzip.toml --custom-template pkgconfig/tmpl/template.toml usr.bin/mkuzip/
scancode -clpeui -n 16 --include "*.c" --include="*.h" --custom-output pkgconfig/FreeBSD-xz.toml --custom-template pkgconfig/tmpl/template.toml contrib/xz/
scancode -clpeui -n 16 --include "*.c" --include="*.h" --custom-output pkgconfig/FreeBSD-zstd.toml --custom-template pkgconfig/tmpl/template.toml sys/contrib/zstd/
scancode -clpeui -n 16 --include "*.c" --include="*.h" --custom-output pkgconfig/FreeBSD-zlib.toml --custom-template pkgconfig/tmpl/template.toml sys/contrib/zlib/
```

The biggest problem is that licenses are not SPDX compatible in the output. They need to be adjusted manually, and there are misdetections
that must also be corrected manually. The detection rate is around 70-90%.

### These some of Licenses that are included in TOML files

 * [bsd-source-code](https://scancode-licensedb.aboutcode.org/bsd-source-code.html)
 * [bsd-original](https://scancode-licensedb.aboutcode.org/bsd-original.html)
 * [bsd-new](https://scancode-licensedb.aboutcode.org/bsd-new.html)
 * [bsd-simplified](https://scancode-licensedb.aboutcode.org/bsd-simplified.html)
 * [bsd-1-clause](https://scancode-licensedb.aboutcode.org/bsd-1-clause.html)
 * [bsd-zero](https://scancode-licensedb.aboutcode.org/bsd-zero.html)
 * [freebsd-first](https://scancode-licensedb.aboutcode.org/freebsd-first.html)
 * [softfloat-2.0](https://scancode-licensedb.aboutcode.org/softfloat-2.0.html)
 * [ibm-dhcp](https://scancode-licensedb.aboutcode.org/ibm-dhcp.html)
 * [isc](https://scancode-licensedb.aboutcode.org/isc.html)
 * [mit](https://scancode-licensedb.aboutcode.org/mit.html)
 * [zlib](https://scancode-licensedb.aboutcode.org/zlib.html)
 * [gpl-2.0](https://scancode-licensedb.aboutcode.org/gpl-2.0.html)
 * [historical](https://scancode-licensedb.aboutcode.org/historical.html)

Currently they are changed with these sed commands:
```
sed -i 's/"bsd-source-code"/"BSD-Source-Code"/' *.toml
sed -i 's/"bsd-original"/"BSD-4-Clause"/' *.toml
sed -i 's/"bsd-new"/"BSD-3-Clause"/' *.toml
sed -i 's/"bsd-simplified"/"BSD-2-Clause"/' *.toml
sed -i 's/"bsd-1-clause"/"BSD-1-Clause"/' *.toml
sed -i 's/"bsd-zero"/"0BSD"/' *.toml
sed -i 's/"freebsd-first"/"LicenseRef-scancode-freebsd-first"/' *.toml
sed -i 's/"softfloat-2.0"/"LicenseRef-scancode-softfloat-2.0"/' *.toml
sed -i 's/"ibm-dhcp"/"LicenseRef-scancode-ibm-dhcp"/' *.toml
sed -i 's/"isc"/"ISC"/' *.toml
sed -i 's/"mit"/"MIT"/' *.toml
sed -i 's/"zlib"/"Zlib"/' *.toml
sed -i 's/"historical"/"HPND"/' *.toml
sed -i 's/"gpl-2.0"/"GPL-2.0-only"/' *.toml
sed -i 's/"bsd-new OR gpl-2.0"/"BSD-3-Clause OR GPL-2.0-only"/' *.toml
sed -i 's/"bsd-new AND isc"/"BSD-3-Clause OR ISC"/' *.toml

```

## Conclusion

By utilizing the provided `.pc` files and `pkgconf`, developers can effectively manage and visualize software dependencies, making it easier to create comprehensive SBOMs for C projects on FreeBSD. As 
this is an ongoing work in progress, further enhancements and additions may be made to improve the utility of these tools.

REUSE toml files are considered purely additional and they can be skipped but for SBOM comprehensiveness, they should be in place when it seems suitable.

