// swift-tools-version:6.1
import PackageDescription

let sharedSwiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("InternalImportsByDefault"),
    PlatformRequirements.clockAPI.availabilityMacro,
    PlatformRequirements.gRPCSwift.availabilityMacro,
]

let package = Package(
    name: "swift-otel",
    platforms: PlatformRequirements.clockAPI.supportedPlatforms,
    products: [
        .library(name: "CandleOTel", targets: ["CandleOTel"]),
    ],
    traits: [
        .trait(name: "OTLPHTTP"),
        .trait(name: "OTLPGRPC"),
        .default(enabledTraits: ["OTLPHTTP", "OTLPGRPC"]),
    ],
    dependencies: [
        .package(url: "https://github.com/candlefinance/candle-swift-distributed-tracing.git", branch: "fix-candle-1.2.2"),
        .package(url: "https://github.com/candlefinance/candle-swift-log.git", branch: "fix-candle-1.6.3"),
        .package(url: "https://github.com/candlefinance/candle-swift-collections.git", branch: "fix-candle-1.1.4"),
        .package(url: "https://github.com/candlefinance/candle-swift-async-algorithms.git", branch: "fix-candle-1.0.4"),
        .package(url: "https://github.com/candlefinance/candle-swift-service-lifecycle.git", branch: "fix-candle-2.8.0"),
        .package(url: "https://github.com/candlefinance/candle-swift-nio.git", branch: "fix-candle-2.82.1"),
        .package(url: "https://github.com/candlefinance/candle-swift-nio-ssl.git", branch: "fix-candle-2.33.0"),
        .package(url: "https://github.com/candlefinance/candle-swift-atomics.git", branch: "fix-candle-1.2.0"),
        .package(url: "https://github.com/candlefinance/candle-swift-metrics.git", branch: "fix-candle-2.7.1"),
        .package(url: "https://github.com/candlefinance/candle-swift-w3c-trace-context.git", branch: "fix-candle-1.0.0-beta.3"),

        // MARK: - OTLPCore

        .package(url: "https://github.com/candlefinance/candle-swift-protobuf.git", branch: "fix-candle-1.30.0"),

        // MARK: - OTLPGRPC

        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "2.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-protobuf.git", from: "2.0.0"),

        // MARK: - OTLPHTTP

        .package(url: "https://github.com/candlefinance/candle-async-http-client.git", branch: "fix-candle-1.27.0"),

        // MARK: - Plugins

        .package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "CandleOTel",
            dependencies: [
                // API
                .product(name: "CandleLogging",package: "candle-swift-log"),
                .product(name: "CandleMetrics",package: "candle-swift-metrics"),
                .product(name: "CandleTracing",package: "candle-swift-distributed-tracing"),
                .product(name: "CandleServiceLifecycle",package: "candle-swift-service-lifecycle"),
                // Core
                .product(name: "CandleAsyncAlgorithms",package: "candle-swift-async-algorithms"),
                .product(name: "CandleDequeModule",package: "candle-swift-collections"),
                .product(name: "CandleNIOConcurrencyHelpers",package: "candle-swift-nio"),
                .product(name: "CandleAtomics",package: "candle-swift-atomics"),
                .product(name: "CandleW3CTraceContext",package: "candle-swift-w3c-trace-context"),
                /// NOTE: Using `.when(traits: ["A", "B"])` is supposed to work as an OR, but is currently broken.
                ///       so we "splat" it into two conditional dependencies. This produces a build warning about a
                ///       duplicate dependency when both traits are enabled (which is the default, too), but it's the
                ///       best we can do until the SwiftPM issue is addressed.
                // Depend on this if either trait is enabled.
                // .product(name: "SwiftProtobuf",package: "candle-swift-protobuf", condition: .when(traits: ["OTLPHTTP", "OTLPGRPC"])),
                .product(name: "CandleSwiftProtobuf",package: "candle-swift-protobuf", condition: .when(traits: ["OTLPHTTP"])),
                // .product(name: "CandleSwiftProtobuf",package: "candle-swift-protobuf", condition: .when(traits: ["OTLPGRPC"])),
                // OTLP/HTTP exporter -- only when OTLPHTTP trait is enabled.
                .product(name: "CandleAsyncHTTPClient",package: "candle-async-http-client", condition: .when(traits: ["OTLPHTTP"])),
                .product(name: "CandleNIOSSL",package: "candle-swift-nio-ssl", condition: .when(traits: ["OTLPHTTP"])),
            ],
            swiftSettings: sharedSwiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)

/// A set of related platform requirements to prevent version drift in availability annotations and package platforms.
struct PlatformRequirements {
    private let name, macOS, iOS, tvOS, watchOS, visionOS: String

    /// Platform requirements for use within a package manifest.
    var supportedPlatforms: [SupportedPlatform] {
        [.macOS(macOS), .iOS(iOS), .tvOS(tvOS), .watchOS(watchOS), .visionOS(visionOS)]
    }

    /// Swift setting to enable a custom availability macro for this set of platform requirements.
    ///
    /// This creates a shorthand availability annotation that can be used instead of writing out the full platform list.
    ///
    /// First add the Swift setting to your targets:
    ///
    /// ```swift
    /// .target(
    ///     name: "MyTarget",
    ///     swiftSettings: [PlatformRequirements.myFeature.availabilityMacro]
    /// )
    /// ```
    ///
    /// Then in your source code, use the annotation:
    ///
    /// ```swift
    /// @available(MyFeature, *)
    /// func newAPIMethod() { ... }
    /// ```
    ///
    /// This is equivalent to the following, but allows a clear reason for why the annotation exists and a central way
    /// to manage the associated platform version requirements:
    ///
    /// ```swift
    /// @available(macOS 13, iOS 16, tvOS 16, watchOS 9, visionOS 1, *)
    /// func newAPIMethod() { ... }
    /// ```
    var availabilityMacro: SwiftSetting {
        .enableExperimentalFeature("AvailabilityMacro=\(name) : macOS \(macOS), iOS \(iOS), tvOS \(tvOS), watchOS \(watchOS), visionOS \(visionOS)")
    }

    static let clockAPI = Self(name: "ClockAPI", macOS: "13", iOS: "16", tvOS: "16", watchOS: "9", visionOS: "1")
    static let gRPCSwift = Self(name: "gRPCSwift", macOS: "15", iOS: "18", tvOS: "18", watchOS: "11", visionOS: "2")
}
