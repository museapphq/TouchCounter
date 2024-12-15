# TouchCounter

A lightweight Swift package that tracks the number of active direct touches on the screen in real-time.

## Features

- Tracks number of simultaneous direct touches
- Thread-safe with `@MainActor` protection
- Minimal performance impact using method swizzling
- Simple singleton API

## Installation

Add this package to your Xcode project using Swift Package Manager: 

``` swift
dependencies: [
    .package(url: "https://github.com/museapphq/TouchCounter", branch: "main")
]
```