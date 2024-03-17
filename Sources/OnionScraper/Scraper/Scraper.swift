//
//  Scraper.swift
//  
//
//  Created by Leonardo Lobato on 06/05/23.
//

import Foundation
import ScreenScraperClient

struct PlatformFolder {
    let name: String
    let platform: Platform
}

struct File {
    let path: URL
    let size: UInt64
    let sha1: String
    let romType: RomType
    let platform: Platform
    init(_ path: URL, size: UInt64, sha1: String, romType: RomType, platform: Platform) {
        self.path = path
        self.size = size
        self.sha1 = sha1
        self.romType = romType
        self.platform = platform
    }
}

enum MediaType: String {
    case cover
    case screenshot
    case box3d
    case titleScreenshot
    case wheel
    case marquee
    case texture

    func screenScraperKey() -> String {
        switch self {
        case .cover: return "box-2D"
        case .screenshot: return "ss"
        case .wheel: return "wheel"
        case .marquee: return "screenmarquee"
        case .texture: return "box-texture"
        case .box3d: return "box-3D"
        case .titleScreenshot: return "sstitle"
        }
    }
}

struct Scraper {

    let basePath: String // "Roms"
    let mediaType: MediaType
    let threads: Int
    let client: ScreenScraper

    init(basePath: String, mediaType: MediaType = .cover, threads: Int = 1, username: String, password: String) {
        self.basePath = basePath
        self.mediaType = mediaType
        self.threads = threads

        let config = ScreenScraper.Configuration(
            devId: Keys.ScreenScraper.devId,
            devPassword: Keys.ScreenScraper.devPassword,
            client: "OnionScraper",
            username: username,
            password: password
        )
        self.client = ScreenScraper(config)
    }

    // MARK: - Configuration

    let folders: [PlatformFolder] = Scraper.folders

    static let folders: [PlatformFolder] = [
        PlatformFolder(name:"ATARI", platform: .atari2600),
        PlatformFolder(name:"DOS", platform: .dos),
        PlatformFolder(name:"FC", platform: .nes),
        PlatformFolder(name:"GB", platform: .gameboy),
        PlatformFolder(name:"GBA", platform: .gameboyAdvance),
        PlatformFolder(name:"GBC", platform: .gameboyColor),
        PlatformFolder(name:"GG", platform: .gameGear),
        PlatformFolder(name:"MD", platform: .megaDrive),
        PlatformFolder(name:"MS", platform: .masterSystem),
        PlatformFolder(name:"MSX", platform: .msx),
        PlatformFolder(name:"NEOGEO", platform: .neoGeo),
        PlatformFolder(name:"NGP", platform: .neoGeoPocketColor),
        PlatformFolder(name:"PCE", platform: .pcengine),
        PlatformFolder(name:"PCECD", platform: .pcengineCd),
        PlatformFolder(name:"PS", platform: .playstation),
        PlatformFolder(name:"SCUMMVM", platform: .scummVm),
        PlatformFolder(name:"SEGACD", platform: .megaCd),
        PlatformFolder(name:"SFC", platform: .snes),
        PlatformFolder(name:"SGFX", platform: .supergrafx),
        PlatformFolder(name:"THIRTYTWOX", platform: .sega32x),
        PlatformFolder(name:"WS", platform: .wonderSwanColor),
        PlatformFolder(name:"X68000", platform: .x68000),
        PlatformFolder(name:"ZXS", platform: .zxSpectrum),
    ]

    let imageFolderName: String = "Imgs"

    let preferredRegions: [ScreenScraperClient.Region] = [.wor, .eu, .us, .uk, .de, .jp, .br]
    let preferredLanguages: [ScreenScraperClient.Language] = [.en, .ja, .pt, .de, .fr, .es, .it, .sv, .nl, .no, .fi, .ko, .pl, .zh, .ru, .tr, .cz, .sk, .hu, .da]

    // MARK: - Public interface

    func scrape(_ platforms: String? = nil, skip: String? = nil) async throws {
        var folders: [PlatformFolder] = self.folders
        let platforms = platforms?.lowercased().components(separatedBy: ",") ?? folders.map({ $0.name.lowercased() })
        let skip = (skip ?? "").lowercased().components(separatedBy: ",")
        folders = folders.filter({ platforms.contains($0.name.lowercased()) && !skip.contains($0.name.lowercased()) })

        for folder in folders {
            guard FileManager.default.fileExists(atPath: path(for: folder).path) else {
                continue
            }
            print("## \(folder.name) --------")
            try await self.scrape(folder)
        }
    }

    // MARK: - Scraping

    enum ScraperError: Error {
        case failedToHashFile
        case failedToSizeFile
        case failedToReadFile
        case noMediaAvailable
    }

    private func path(for folder: PlatformFolder) -> URL {
        return URL(filePath: self.basePath).appending(path: folder.name, directoryHint: .isDirectory)
    }

    private func scrape(_ folder: PlatformFolder) async throws {
        let path = path(for: folder)
        let files = try files(path, platform: folder.platform)
        print("\(files.count) files")
        guard files.count > 0 else {
            return
        }

        let imageFolder = path
            .appending(path: self.imageFolderName, directoryHint: .isDirectory)
        do {
            try FileManager.default.createDirectory(at: imageFolder, withIntermediateDirectories: true)
        } catch {
            print("Error creating images directory: \(error)")
            return
        }

        switch folder.platform.romType() {
        case .iso: try await self.scrapeIso(files, folder: folder, imageFolder: imageFolder)
        case .rom: try await self.scrapeRoms(files, folder: folder, imageFolder: imageFolder)
        case .folder: try await self.scrapeFolder(files, folder: folder, imageFolder: imageFolder)
        default:
            print("Not supported.")
            return
        }
    }

    func downloadMetadata(_ file: URL, romType: RomType, platform: Platform, imagePath: URL) async throws -> String {
        guard let sha1 = try? file.sha1() else {
            throw ScraperError.failedToHashFile
        }
        guard
            let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
            let fileSize = attributes[.size] as? UInt64, fileSize > 0
        else {
            throw ScraperError.failedToSizeFile
        }

        print("   Scraping [\(file.lastPathComponent)] sha1:[\(sha1)] bytes:[\(fileSize)]...")

        let gameInfo = try await scrape(File(file, size: fileSize, sha1: sha1, romType: romType, platform: platform))
        let gameName = gameInfo.names.preferred(self.preferredRegions)?.text ?? "<unknown>"
        print("   Game: [\(gameName)]")
        try await self.downloadMedia(gameInfo.medias, imagePath: imagePath)
        return gameName
    }

    func downloadMetadata(_ fileName: String, romType: RomType, platform: Platform, imagePath: URL) async throws -> String {
        print("   Scraping [\(fileName)]...")

        let gameInfo = try await self.client.getGame(
            filename: fileName,
            filesize: nil,
            identifiers: [],
            romType: romType,
            platform: platform
        )
        let gameName = gameInfo.names.preferred(self.preferredRegions)?.text ?? "<unknown>"
        print("   Game: [\(gameName)]")
        try await self.downloadMedia(gameInfo.medias, imagePath: imagePath)
        return gameName
    }

    func imagePath(_ file: URL, imageFolder: URL) -> URL {
        let filename = file.lastPathComponent
        return imageFolder
            .appending(path: filename).deletingPathExtension()
            .appendingPathExtension("png")
    }

    private func scrape(_ file: File) async throws -> GameInfo {
        let gameInfo = try await self.client.getGame(
            filename: file.path.lastPathComponent,
            filesize: file.size,
            identifiers: [.sha1(file.sha1)],
            romType: file.romType,
            platform: file.platform
        )
        return gameInfo
    }

    private func files(_ path: URL, platform: Platform) throws -> [URL] {
        var files = [URL]()
        let filePaths = try FileManager.default.contentsOfDirectory(atPath: path.path)
        var validExtensions = platform.extensions()
        if platform.romType() == .rom {
            validExtensions.append("zip")
        }
        for filename in filePaths {
            let filePath = path.appending(path: filename)
            if platform.romType() == .folder {
                if filePath.isDirectory || validExtensions.contains(filePath.pathExtension.lowercased()) {
                    files.append(filePath)
                }
            } else {
                if !validExtensions.contains(filePath.pathExtension.lowercased()) { continue }
                if filePath.isDirectory { continue }
                files.append(filePath)
            }
        }
        return files
    }

    func downloadMedia(_ media: [Media], imagePath: URL) async throws {
        let preferredMedia = media.filter({ $0.parent == "jeu" && $0.type == self.mediaType.screenScraperKey() })
            .preferred(self.preferredRegions)
        guard let preferredMedia = preferredMedia, let url = URL(string: preferredMedia.url) else {
            print("   No media available.")
            throw ScraperError.noMediaAvailable
        }


        print("   Downloading...")

        let (localURL, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.moveItem(at: localURL, to: imagePath)
        print("   Done.")
    }

}

extension URL {
    var isDirectory: Bool {
       (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}
