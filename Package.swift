import PackageDescription

let package = Package(name: "AFNetworking",
                      platforms: [.macOS(.v10_10),
                                  .iOS(.v9),
                                  .tvOS(.v9),
                                  .watchOS(.v2)],
                      products: [.library(name: "AFNetworking",
                                          targets: ["AFNetworking"])],
                      targets: [.target(name: "AFNetworking",
                                        path: "AFNetworking",
                                        publicHeadersPath: "")])
