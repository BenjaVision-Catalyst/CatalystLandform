# CatalystLandform

Persistent landform domain objects for a Catalyst Runtime service. Catalyst Connect owns transport. Unreal Engine and Voxel Plugin provide presentation and editing interaction.

The current implementation validates Catalyst bounded edit payloads, decodes sparse masked float32 fields, and replays procedural and sampled edits in accepted order. Recovery evaluates an edit at its original fold position and preserves later contributions. Formation and geology evaluation supply the pinned baseline.

## Packages

| Package | Contents |
| --- | --- |
| BVC-Landform-Core | Bounded edit errors, strict JSON and binary readers, sampled fields, verified payloads and ordered replay. |
| BVC-Landform-Examples | GT/Pharo conformance examples and clone-relative fixture access. |
| BaselineOfCatalystLandform | Metacello groups Core, Examples and default; default loads Core. |

Core has no dependency on the legacy CatalystDevKit plugin facade, Unreal or VPP. NeoJSON supplies the JSON reader superclass; SHA256 and the current IEEE/base64/UTF-8 protocols are provided by the host image. The baseline selects the upstream Pharo or GemStone NeoJSON core group for its platform.

## Metacello

In a BVC-managed GT/Pharo environment:

```smalltalk
Metacello new
    baseline: 'CatalystLandform';
    repository: 'github://BenjaVision-Catalyst/CatalystLandform:main/src';
    load: 'Core'.
```

For the examples, load 'Examples' instead. To use the workspace clone:

```smalltalk
Metacello new
    baseline: 'CatalystLandform';
    repository: 'tonel:///absolute/path/to/CatalystLandform/src';
    load: 'Examples'.
```

Register that clone with Iceberg as CatalystLandform before running BVCLandformBoundedEditExamples. Fixtures resolve from that registered repository's fixtures/landform directory, with capture fixtures under fixtures/capture. No developer-specific absolute path is embedded in the packages.

## Rowan

rowan/project.ston defines a Tonel project with packages under src. rowan/specs/CatalystLandform.ston selects the Core component, which loads BVC-Landform-Core without the Metacello baseline or GT examples.

Load the specification using the existing Rowan project tools:

```smalltalk
Rowan projectTools load
    loadProjectFromSpecUrl:
        'file:/absolute/path/to/CatalystLandform/rowan/specs/CatalystLandform.ston'.
```

NeoJSON must already be loaded in the target Rowan environment: its upstream GemStone repository currently has a Metacello/FileTree distribution, not a Rowan project specification. In a GemStone environment with Metacello, the dependency load is:

```smalltalk
Metacello new
    baseline: 'NeoJSON';
    repository: 'github://GsDevKit/NeoJSON:gs_master/filetree';
    load: 'Core'.
```

The Rowan configuration is prepared for GemStone. Loading and numerical conformance on the target GemStone 4.x environment remain unverified; the current implementation and conformance execution are in GT/Pharo. A successful metadata parse does not qualify platform-specific IEEE, hashing or string behavior.

## Fixtures and draft contracts

fixtures contains the Catalyst-authored portable geometry, arithmetic, malformed-input and recovery corpus. contracts contains the corresponding draft schemas. All protocol identities remain /draft; the agreed first release becomes version 1.

The 23 GT example groups include 1,024 recorded normalized float32 arithmetic comparisons, resource integrity checks, sparse support, mixed replay and recovery. The recorded arithmetic expectations came from the earlier standalone source-derived proof; this repository contains no extracted commercial VPP implementation or plugin binaries. These checks do not claim live Unreal or VPP execution.

## Development

Edit Smalltalk in the running BVC-managed image. Use the registered CatalystLandform Iceberg repository to review, save and publish source. GemStone is the target for the Runtime service; service activation and Catalyst Connect transport wiring remain outside these domain packages.
