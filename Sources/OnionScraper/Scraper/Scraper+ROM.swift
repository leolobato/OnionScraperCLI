//
//  Scraper+ROM.swift
//  
//
//  Created by Leonardo Lobato on 13/05/23.
//

import Foundation
import ScreenScraperClient

extension Scraper {

    func scrapeRoms(_ files: [URL], folder: PlatformFolder, imageFolder: URL) async throws {
        await withTaskGroup(of: Void.self) { group in
            for (index, file) in files.enumerated() {
                if index >= self.threads { await group.next() }
                let filename = file.lastPathComponent
                print("-  [\(index)/\(files.count)] [\(filename)]...")

                let imagePath = self.imagePath(file, imageFolder: imageFolder)
                if FileManager.default.fileExists(atPath: imagePath.path) {
                    print("   Image exists.")
                    continue
                }

                print("   Scraping...")

                group.addTask {
                    do {
                        let _ = try await downloadMetadata(
                            file,
                            romType: .rom,
                            platform: folder.platform,
                            imagePath: imagePath
                        )
                    } catch {
                        print("   Failed: \(error)")
                    }
                }
            }

            await group.waitForAll()
        }
    }

}
