
## SBOM Directory Structure

This directory is an example of how to create Software Bill Of Materials (SBOM) specifically for FreeBSD. The example uses `cat(1)` utility as a showcase.

### File Formats
- **UCL**: Contains all needed information in UCL format.
- **pkgconfig**: Contains all needed information in `pkgconf` format.
- **jsonld**: Contains the output in JSON-LD format, demonstrating the SBOM generated from `pkgconfig/cat.pc`.

## Directories

### UCL Directory
The files under the `ucl` directory are provided to explore if metadata should be stored as UCL or directly as `.pc` files. For creating SPDX Lite 3.0.1 SBOM, only the `.pc` files in the `pkgconfig` directory are needed.

**Reasoning for Inclusion**:
- UCL files were initially included because there is a parser for UCL in FreeBSD.
- Pkgconf-files lack Lua bindings, which might be required for certain use cases.

### JSON-LD Directory
The `jsonld` directory contains example outputs in JSON-LD format. This demonstrates the SBOM generated from `pkgconfig/cat.pc`, including dependencies not present in the `pkgconfig` directory.

## Collecting Information

Both UCL and `.pc` files can be created using information provided by [scancode-toolkit](https://scancode-toolkit.readthedocs.io/en/stable/). This tool is formulated with a Lua script to convert data into UCL or `.pc` file formats.

### Variables in .pc File

- **Name**: Name of the program, application, or library.
- **Description** (optional): Description of the program, application, or library.
- **URL** (optional): Homepage. For FreeBSD, this typically links to a man-page URL.
- **Version** (optional but recommended): Version number. Should match the release number.
- **Source**: Location to find sources for this package. This should link to the correct release tag or hash in FreeBSD CGit.
- **License**: SPDX expression of license.
- **License.file**: File(s) containing the correct license text.
- **Copyright**: Contains copyright information for this package.
- **Requires**: Dependencies required by the software.
