//
//  Scraper+ISO.swift
//  
//
//  Created by Leonardo Lobato on 13/05/23.
//

import Foundation
import ScreenScraperClient

struct CueFile {
    let files: [String]

    init(_ fileContents: String) {
        var files = [String]()

        let regex = try! NSRegularExpression(pattern: "^FILE \"(.*?)\"", options: [.anchorsMatchLines])
        let range = NSRange(location: 0, length: fileContents.utf8.count)
        let matches = regex.matches(in: fileContents, range: range)
        for match in matches {
            guard let range = Range(match.range(at: 1), in: fileContents) else { continue }
            let file = String(fileContents[range])
            files.append(file)
        }

        self.files = files
    }
}

extension Scraper {

    func scrapeIso(_ files: [URL], folder: PlatformFolder, imageFolder: URL) async throws {

        let cueFiles = files.filter({ $0.pathExtension.lowercased() == "cue" })

        for cueFile in cueFiles {
            print("-  [\(cueFile.lastPathComponent)]:")
            let imagePath = self.imagePath(cueFile, imageFolder: imageFolder)
            if FileManager.default.fileExists(atPath: imagePath.path) {
                print("   Image exists.")
                continue
            }

            let gameName = try? await downloadMetadata(
                cueFile,
                romType: folder.platform.romType(),
                platform: folder.platform,
                imagePath: imagePath
            )
            if gameName != nil {
                // Found.
                return
            }

            guard let contents = try? String(contentsOfFile: cueFile.path) else {
                continue
            }
            let cue = CueFile(contents)
            for file in cue.files {
                let fileUrl = cueFile.deletingLastPathComponent().appending(path: file)
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

        // TODO: Scrape other files that are not cue/bin
        // - remove cue and its bins from the list of files
        // - scrape remaining

        /*
         case .supergrafx:  return ["pce","cue","ccd","sgx"]
         case .megaCd:      return ["bin","ccd","chd","cue","img","iso","sub","wav"]
         case .sega32x:     return ["32x","smd","md","bin","ccd","cue","img","iso","sub","wav"]
         case .playstation: return ["iso","bin","ccd","cue","pbp","cbn","img","mdf","m3u","toc","znx","chd"]
         */


    }
}
