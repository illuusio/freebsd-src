# Understanding the FreeBSD-SPDX-Lite-Profile Example

This document explains the structure of the `FreeBSD-SPDX-Lite-profile-example.json` file, which uses **JSON-LD** (a format for linked data) to represent SPDX (Software Package Data Exchange) metadata version 3.0.1. The goal is to clarify how each part of the file connects to the SPDX standard and why it matters.

---

## 📁 Header: Where to Find the Structure

The file starts with a header that tells us where to find the structure (or "schema") for this JSON-LD document. This is crucial because it defines how the rest of the file should be interpreted.

```json
{
  "@context": "https://spdx.org/rdf/3.0.1/spdx-context.jsonld",
  "@graph": [
```

- `@context` points to the **SPDX JSON-LD context**, which defines the types and relationships used in the document.
- `@graph` is a list of all the elements in the SPDX document.

---

## 📦 Core: The SPDX Document

The `SpdxDocument` is the main container for all SPDX metadata. It includes:

- A **collection of elements** (like licenses, packages, and relationships).
- Links to **one or more SBOMs** (Software Bill of Materials), which list the components in a software product.

In this example:
- There's **one package** and **one SBOM**.
- The SBOM links to the package, showing it's part of the product.

It looks like this:
```json
    {
      "@type": "SpdxDocument",
      "spdxId": "https://freebsd.org/git/f72908c/Document/1",
      "creationInfo": "_:creationinfo_1",
      "rootElement": [
        "https://freebsd.org/git/f72908c/Sbom/1"
      ],
      "element": [
        "https://freebsd.org/git/f72908c/Sbom/1"
      ],
      "dataLicense": "FreeBSD-DOC"
    },
```

---

## 📦 Linking SBOM together

The `software_Sbom` section describes the SBOM and its contents. It links to every resource available for single package to produce SBOM out of it:

```json
    {
      "@type": "software_Sbom",
      "spdxId": "https://freebsd.org/git/f72908c/Sbom/1",

      "creationInfo": "_:creationinfo_1",
      "element": [
        "https://freebsd.org/git/f72908c/Agent/amon_navi",
        "https://freebsd.org/git/f72908c/Agent/freebsd-14.3-amd64-123",
        "https://freebsd.org/git/f72908c/Agent/freebsd_project",
        "https://freebsd.org/git/f72908c/LicenseExpression/BSD-2-Clause",
        "https://freebsd.org/git/f72908c/Package/example",
        "https://freebsd.org/git/f72908c/Relationship/1",
        "https://freebsd.org/git/f72908c/Relationship/2",
        "https://freebsd.org/git/f72908c/Relationship/3",
        "https://freebsd.org/git/f72908c/SimpleLicensingText/BSD-2-Clause"
      ],
      "rootElement": [
        "https://freebsd.org/git/f72908c/Package/example"
      ],
      "software_sbomType": [
        "build"
      ]
    },
```

- `@type` tells us this is a Software element.
- `spdxId` is a unique identifier for this SBOM.
- The `name` and `version` fields describe the software product.

This SBOM is for imagenary package **example** which is not part of FreeBSD!
---

## 🧾 CreationInfo: Who Created This?

The `CreationInfo` section tells us who created the document, when, and how:

```json
    {
      "@type": "CreationInfo",
      "@id": "_:creationinfo_1",
      "created": "2025-09-22T00:00:00Z",
      "createdBy": [
        "https://freebsd.org/git/f72908c/Agent/amon_navi"
      ],
      "specVersion": "3.0.1"
    },
```

- `created` is the date and time the document was created.
- `createdBy` is the machine, organization or person who made the document.

This helps ensure the metadata is trustworthy and traceable.

---

## 👥 Agents: Who Was Involved?

Agents are the people, machines, or organizations involved in creating the SPDX document:

```json
    {
      "@type": "Agent",
      "creationInfo": "_:creationinfo_1",
      "name": "Amon Navi",
      "spdxId": "https://freebsd.org/git/f72908c/Agent/amon_navi"
    },
    {
      "@type": "Agent",
      "creationInfo": "_:creationinfo_1",
      "description": "FreeBSD 14.3 builder number 123 for AMD64 architecture",
      "name": "FreeBSD-14.3-amd64-123",
      "spdxId": "https://freebsd.org/git/f72908c/Agent/freebsd-14.3-amd64-123"
    },
    {
      "@type": "Agent",
      "creationInfo": "_:creationinfo_1",
      "description": "FreeBSD is an operating system used to power modern servers, desktops, and embedded platforms.",
      "name": "FreeBSD Project",
      "spdxId": "https://freebsd.org/git/f72908c/Agent/freebsd_project"
    },
```

- `name` identifies the agent.
- This helps clarify who is responsible for the metadata.

---

## 📜 Package: The Software Component

A `Package` is a single component in the software product (like a library or tool). Like said this one is imagenary example package which is not part of FreeBSD:

```json
    {
      "@type": "Package",
      "builtTime": "2025-09-22T00:00:00Z",
      "creationInfo": "_:creationinfo_1",
      "name": "example",
      "originatedBy": [
                        "https://freebsd.org/git/f72908c/Agent/freebsd_project",
                        "https://freebsd.org/git/f72908c/Agent/freebsd-14.3-amd64-123"
                      ],
      "software_copyrightText": "NOASSERTION",
      "software_packageVersion": "1.0.0",
      "suppliedBy": "https://freebsd.org/git/f72908c/Agent/freebsd_project",
      "spdxId": "https://freebsd.org/git/f72908c/Package/example"
    },
```

- `name` and `version` describe the component.
- This package might be part of the FreeBSD project and is linked to the SBOM.

---

## 📜 License: The Legal Terms

Licenses define how the software can be used. They should come in two forms:

1. **License Expression**: A short identifier (like `BSD-2-Clause`).
2. **License Text**: The full legal text of the license.

```json
    {
      "@type": "simplelicensing_LicenseExpression",
      "spdxId": "https://freebsd.org/git/f72908c/LicenseExpression/BSD-2-Clause",
      "creationInfo": "_:creationinfo_1",
      "simplelicensing_licenseExpression": "BSD-2-Clause"
    },
    {
      "@type": "simplelicensing_SimpleLicensingText",
      "creationInfo": "_:creationinfo_1",
      "simplelicensing_licenseText": "This should contain whole\nBSD 2-clause license text",
      "spdxId": "https://freebsd.org/git/f72908c/SimpleLicensingText/BSD-2-Clause"
    },
```
---

## 🔗 Relationships: How Things Are Connected


Relationships show how elements are connected. For example there must have relationships for every package:

- object <u>MUST exist exactly one</u> Relationship object of type **hasConcludedLicense** having that element as its from property and an /SimpleLicensing/AnyLicenseInfo as its to property.
- for every Package object <u>MUST exist exactly one</u> Relationship object of type **hasDeclaredLicense** having that element as its from property and /SimpleLicensing/AnyLicenseInfo object as its to property.
```
    {
      "@type": "Relationship",
      "spdxId": "https://freebsd.org/git/f72908c/Relationship/2",
      "creationInfo": "_:creationinfo_1",
      "from": "https://freebsd.org/git/f72908c/Package/example",
      "to": [
        "https://freebsd.org/git/f72908c/LicenseExpression/BSD-2-Clause",
        "https://freebsd.org/git/f72908c/SimpleLicensingText/BSD-2-Clause"
      ],
      "relationshipType": "hasDeclaredLicense"
    },
    {
      "@type": "Relationship",
      "spdxId": "https://freebsd.org/git/f72908c/Relationship/3",
      "creationInfo": "_:creationinfo_1",
      "from": "https://freebsd.org/git/f72908c/Package/example",
      "to": [
        "https://freebsd.org/git/f72908c/LicenseExpression/BSD-2-Clause",
        "https://freebsd.org/git/f72908c/SimpleLicensingText/BSD-2-Clause"
      ],
      "relationshipType": "hasConcludedLicense"
    }
  ]
}
```

- `from` is the source element (like a package).
- `to` is the target element (like a license).
- `relationshipType` describes the connection (like "hasDeclaredLicense").

---

## 📌 Summary: What This File Achieves

This file:
- Describes a software product (like FreeBSD) and its components.
- Links to the licenses used by those components.
- Shows how the components are connected to the product.
- Provides metadata about who created this information.

It’s a **lightweight** version of SPDX (hence "Lite"), focusing on the essentials needed to describe software and its licensing.

---

## 📚 Learn More

- [SPDX JSON-LD Context](https://spdx.org/rdf/3.0.1/spdx-context.jsonld)
- [SPDX License Expressions](https://spdx.github.io/spdx-spec/annexes/spdx-license-expressions/)
- [SPDX Relationship Types](https://spdx.github.io/spdx-spec/model/core/vocabularies/relationship-type/)
