# ``SwiftSnapshotCore``

The core runtime library for generating type-safe Swift source fixtures from runtime values.

## Overview

SwiftSnapshotCore provides the essential infrastructure for converting Swift values into compilable source code. This library handles value rendering, code formatting, file I/O, and configuration management.

### Key Features

- **Value Rendering**: Convert any Swift type to SwiftSyntax expressions
- **Custom Renderers**: Extensible registry for type-specific rendering logic
- **Code Formatting**: Integration with swift-format and EditorConfig
- **Path Resolution**: Deterministic file naming and directory organization
- **Thread-Safe**: All operations are safe for concurrent use
- **DEBUG-Only**: Zero runtime overhead in production builds

### Core Components

The library is organized into these main subsystems:

- **Runtime API**: ``SwiftSnapshotRuntime`` for exporting values
- **Value Rendering**: ``ValueRenderer`` and ``SnapshotRendererRegistry``
- **Configuration**: ``SwiftSnapshotConfig`` and format profiles
- **Formatting**: ``CodeFormatter`` and ``FormatConfigLoader``
- **Utilities**: ``PathResolver`` for output organization

## Topics

### Essential APIs

- ``SwiftSnapshotRuntime``
- ``SwiftSnapshotConfig``
- ``SnapshotRendererRegistry``

### Value Rendering

- ``ValueRenderer``
- ``SnapshotRenderContext``
- ``SnapshotCustomRenderer``

### Configuration

- ``RenderOptions``
- ``FormatProfile``
- ``FormatConfigSource``

### Error Handling

- ``SwiftSnapshotError``

### Code Formatting

- ``CodeFormatter``
- ``FormatConfigLoader``

### Path Resolution

- ``PathResolver``

### Articles

- <doc:BasicUsage>
- <doc:CustomRenderers>
- <doc:FormattingConfiguration>