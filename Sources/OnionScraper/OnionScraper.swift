import Foundation
import ArgumentParser

@main
struct OnionScraper: AsyncParsableCommand {

    @Argument(help: "Base path where all platforms are. This is the /Roms folder on the Onion SD card.")
    var basePath: String?

    @Option(name: .long, help: "ScreenScraper username.")
    var username: String

    @Option(name: .long, help: "ScreenScraper password.")
    var password: String

    @Option(name: .shortAndLong, help: "Number of threads to use.")
    var threads: Int = 1

    @Option(name: .shortAndLong,
            help: ArgumentHelp(
                "Platforms to scrape, comma separated.",
                discussion: """
If no platform is provided, all platforms will be scraped.\n\
\n\
Valid platforms:\n\(Scraper.folders.map({$0.name}).joined(separator: ", ")).\n\
\n\
Example: --platforms sfc,md,pce\n
"""
            )
    )
    var platforms: String?

    @Option(name: .shortAndLong, help: "Platforms to skip.")
    var skip: String?

    @Option(name: .shortAndLong, help: "Media type to download. Valid options: cover, screenshot, box3d, titleScreenshot, wheel, marquee, texture")
    var mediaType: MediaType = .cover

    mutating func run() async throws {
        let basePath: String = self.basePath ?? FileManager.default.currentDirectoryPath

        let scraper = Scraper(basePath: basePath,
                              threads: threads,
                              username: username,
                              password: password)
        try await scraper.scrape(platforms, skip: skip)
    }
}

extension MediaType: ExpressibleByArgument {

}
