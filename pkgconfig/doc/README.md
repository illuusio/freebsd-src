# SPDX Lite Profile Example for FreeBSD

The SPDX Lite profile 3.0.1 is a simplified way to create a Software Bill of Materials (SBOM) — especially useful when you need to quickly document software components.

For documented version of exmplae SPDX SBOM JSON-LD please see: [FreeBSD-SPDX-Lite-profile-example.md](FreeBSD-SPDX-Lite-profile-example.md) file contains run thru JSON file elements and structure.

For visualised version (how dependencies go) please see: [FreeBSD-SPDX-Lite-profile-example.svg](https://raw.githubusercontent.com/illuusio/freebsd-src/refs/heads/pkgconfig-test/pkgconfig/doc/FreeBSD-SPDX-Lite-profile-example.svg)

## SPDX Document Formats

SPDX documents use **RDF (Resource Description Framework)** to describe data in a structured way. This format can be serialized in several common formats:

- **JSON-LD** (like a database format for linking data)
- **Turtle** (a human-readable format for RDF)
- **N-Triples** (a simple text format for RDF)
- **RDF/XML** (an XML-based format for RDF)

## Type definations
You can find type definitions for [SPDX Context JSON-LD](https://spdx.github.io/spdx-spec/v3.0.1/rdf/spdx-context.jsonld). It helds used types and tags. Documentation for **SDPX 3.0.1** can be [found here](https://spdx.github.io/spdx-spec/v3.0.1/front/introduction/) and SPDX Lite profile requirements [can be found here](https://spdx.github.io/spdx-spec/v3.0.1/annexes/spdx-lite/)

---

## Example Files

This directory contains several example files showing how to format an SPDX Lite profile seiralized in diffrent formats:

- **FreeBSD-SPDX-Lite-profile-example.json** - JSON-LD format (most common)
- **FreeBSD-SPDX-Lite-profile-example.nt** - N-Triples format
- **FreeBSD-SPDX-Lite-profile-example.ttl** - Turtle format
- **FreeBSD-SPDX-Lite-profile-example.xml** - XML format

Other than JSON-LD files were generated using Python's [RDFlib](https://rdflib.readthedocs.io/) library.

---

## Key Concepts

### SPDX ID

Every element in an SPDX document needs a unique identifier. This is called an `spdxId` and looks like this:

```json
"spdxId": "https://freebsd.org/git/f72908c/Package/example/1"
```

This format helps track which commit the SBOM references. The last part of the ID is usually a number that starts at 1 for each new version.

# spdxId Exceptions

## Creation Info

The `creationInfo` section doesn't have an `spdxId`, but it still needs a unique identifier. It looks like this:

```json
"@id": "_:creationinfo_1"
```

This helps link the SBOM to the process that created it.

## Agents

An "agent" is anything that can take action — like a person, a software tool, or a build machine. Here's how you might represent person:

```json
"spdxId": "https://freebsd.org/git/f72908c/Agent/amon_navi"
```

Or for a build machine:

```json
"spdxId": "https://freebsd.org/git/f72908c/Agent/freebsd-14.3-amd64-123"
```

### Packages

Each package in SBOM needs a unique identifier. Here's how their spdxId is represented. In this example we use imagenary example-package:

```json
"spdxId": "https://freebsd.org/git/f72908c/Package/example"
```

Note that package names are case-sensitive — `Example` and `example` are different.

### Licenses

Licenses are also referenced using a special format. For example, the BSD 2-Clause license would look like this:

```json
"spdxId": "https://freebsd.org/git/f72908c/LicenseExpression/BSD-2-Clause"
```

Or for the simple licensing text:

```json
"spdxId": "https://freebsd.org/git/f72908c/SimpleLicensingText/BSD-2-Clause"
```

---

## Summary

SPDX Lite is a streamlined way to create SBOMs that's easy to use and understand. By using standardized formats like JSON-LD, Turtle, or XML, you can create SBOMs that are both human-readable and machine-processable. The key is to use unique identifiers and follow the structure described in the SPDX specification.
