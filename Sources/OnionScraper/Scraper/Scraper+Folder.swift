//
//  File.swift
//  
//
//  Created by Leonardo Lobato on 13/05/23.
//

import Foundation

extension Scraper {

    // TODO:
    // - Protocol for FileScraper
    // - Return not found files

    func scrapeFolder(_ files: [URL], folder: PlatformFolder, imageFolder: URL) async throws {
        let validExtensions = folder.platform.extensions()

        for gameFolder in files {
            guard gameFolder.isDirectory else {
                continue
            }
            print("-  [\(gameFolder.lastPathComponent)]:")
            let imagePath = self.imagePath(gameFolder, imageFolder: imageFolder)
            if FileManager.default.fileExists(atPath: imagePath.path) {
                print("   Image exists.")
                continue
            }

            let gameName = try? await downloadMetadata(
                gameFolder.lastPathComponent,
                romType: folder.platform.romType(),
                platform: folder.platform,
                imagePath: imagePath
            )
            if gameName != nil {
                // Found.
                continue
            }

            let filePaths = try FileManager.default.contentsOfDirectory(atPath: gameFolder.path)

            for file in filePaths {
                let fileUrl = gameFolder.appending(path: file)
                if validExtensions.count > 0 && !validExtensions.contains(fileUrl.pathExtension.lowercased()) { continue }
                let gameName = try? await downloadMetadata(
                    fileUrl,
                    romType: folder.platform.romType(),
                    platform: folder.platform,
                    imagePath: imagePath
                )
                if gameName != nil {
                    // Found.
                    break
                }
            }

        }

    }
}
