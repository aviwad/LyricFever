# CompactSlider local copy

This directory contains the `Package.swift`, `Sources`, and MIT license from
[CompactSlider 1.2.1](https://github.com/buh/CompactSlider/tree/1.2.1)
(commit `e5219ff353613b6493bfe5a3333c3bfa2d1e4d57`).

The only source change wraps a gradient in `AnyView` to select the SwiftUI
`View.opacity` overload when building against the macOS 27 SDK. The project
uses this local copy until the dependency can be upgraded without changing
the existing slider behavior.
