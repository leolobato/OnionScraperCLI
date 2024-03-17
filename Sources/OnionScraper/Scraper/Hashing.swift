//
//  Hashing.swift
//  
//
//  Created by Leonardo Lobato on 11/04/23.
//

import Foundation
import CryptoKit

public extension URL {

    func sha1() throws -> String {
        let bufferSize = 16*1024

        // Open file for reading:
        let file = try FileHandle(forReadingFrom: self)
        defer {
            file.closeFile()
        }

        // Create and initialize MD5 context:
        var hash = CryptoKit.Insecure.SHA1()

        // Read up to `bufferSize` bytes, until EOF is reached, and update MD5 context:
        while autoreleasepool(invoking: {
            let data = file.readData(ofLength: bufferSize)
            if data.count > 0 {
                hash.update(data: data)
                return true // Continue
            } else {
                return false // End of file
            }
        }) { }

        // Compute the MD5 digest:
        let data = Data(hash.finalize())

        return data.hex()
    }
}

public extension Data {

    func sha1() -> String {
        let data = Data(CryptoKit.Insecure.SHA1.hash(data: self))
        return data.hex()
    }

    func hex() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
