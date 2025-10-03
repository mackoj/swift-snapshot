# Original Specification Documents

This directory contains the original specification and implementation plan documents created during the design phase of SwiftSnapshot.

## Status

These documents are **historical references** that describe the initial design goals and implementation strategy. The library has been fully implemented and is in active use.

## Current Documentation

For up-to-date documentation on the **actual implementation**, see:

- [What is SwiftSnapshot and Why?](../WhatAndWhy.md) - Purpose and use cases
- [Architecture Overview](../Architecture.md) - Technical design and implementation
- [Basic Usage](../BasicUsage.md) - Getting started guide
- [Custom Renderers](../CustomRenderers.md) - Type-specific rendering
- [Formatting Configuration](../FormattingConfiguration.md) - Code style setup

## Specification Documents

### Library Specifications

- **LIBRARY_SPECIFICATION.md** - Original runtime library specification
- **LIBRARY_IMPLEMENTATION_PLAN.md** - Phased implementation strategy for the runtime

### Macro Specifications

- **MACRO_SPECIFICATION.md** - Original macro system specification
- **MACRO_IMPLEMENTATION_PLAN.md** - Phased implementation strategy for macros

## Implementation Notes

The implementation closely follows the original specifications with these key changes:

1. **Simplified Phases**: Implementation was completed in fewer phases than originally planned
2. **Enhanced Integration**: Better integration with swift-dependencies for testability
3. **Improved Error Handling**: More comprehensive error reporting using swift-issue-reporting
4. **EditorConfig Support**: Full integration with .editorconfig files
5. **Documentation**: Extensive DocC documentation following Apple guidelines

## Using These Documents

These specifications are useful for:

- **Understanding Design Rationale**: See why certain design decisions were made
- **Historical Reference**: Compare original intent with actual implementation
- **Future Development**: Reference when planning new features
- **Onboarding**: Help new contributors understand the project's evolution

## See Also

- [README.md](../../../../../README.md) - Project overview and quick start
- [Architecture.md](../Architecture.md) - Current system architecture
- Main documentation at [developer.apple.com/documentation](https://developer.apple.com/documentation) (once published)
