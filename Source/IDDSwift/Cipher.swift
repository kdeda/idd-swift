//
//  Cipher.swift
//  IDDSwift
//
//  Created by Klajd Deda on 4/3/24.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation
import Crypto

/**
 Simple symetric key cipher. For more fun the key can be a password of our choosing.
 For more noise the password could be a random string like an uuidgen.
 */
public struct Cipher: Sendable {
    /**
     https://www.swift.org/blog/crypto/
     https://stackoverflow.com/questions/56828125/how-do-i-access-the-underlying-key-of-a-symmetrickey-in-cryptokit
     */
    private var symmetricKeyRandom: SymmetricKey {
        let key = "Xp6F3VPvnomR29hS7N+J3rEN81QR3EUbzTLDoaJ6Sv4="
        guard let data = Data(base64Encoded: key)
        else {
            logError?("symmetricKey failed to create")
            return SymmetricKey(size: .bits256)
        }

        let rv = SymmetricKey(data: data)

        // to create a key
        // let key1 = SymmetricKey(size: .bits256)
        // let key1String = key1.withUnsafeBytes { body in
        //     Data(body).base64EncodedString()
        // }
        // logger.info("symmetricKey: '\(rv)'")
        // Log4swift[Self.self].info("symmetricKey: '\(rv)'")
        return rv
    }

    /// Create one with password
    private var symmetricKey: SymmetricKey {
        guard let data = password.data(using: .utf8)
        else {
            logError?("symmetricKey failed to create with password")
            return SymmetricKey(size: .bits256)
        }
        let hash = SHA256.hash(data: data)
        let hashString = hash.map { String(format: "%02hhx", $0) }.joined()
        let subString = String(hashString.prefix(32))
        let keyData = subString.data(using: .utf8)!
        return SymmetricKey(data: keyData)
    }

    var password: String
    var version: Int
    var logInfo: (@Sendable (_ message: String) -> Void)?
    var logError: (@Sendable (_ message: String) -> Void)?

    /**
     password shall be a random uuid for more noise
     */
    public init(
        password: String = "CFB6372F-0C02-4892-9744-FC09789A8EB6",
        version: Int = 1,
        logInfo: (@Sendable (_ message: String) -> Void)? = nil,
        logError: (@Sendable (_ message: String) -> Void)? = nil
    ) {
        self.password = password
        self.version = version
        self.logInfo = logInfo
        self.logError = logError
    }

    public func encrypt(_ string: String) -> String {
        guard let data = string.data(using: .utf8),
              let encrypted = encrypt(data)
        else { return "" }

        return encrypted.base64EncodedString()
    }

    public func encrypt(_ data: Data) -> Data? {
        do {
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
            return sealedBox.combined
        } catch {
            logError?("error: '\(error)'")
        }
        return nil
    }

    public func decrypt(_ string: String) -> String {
        guard let data = Data(base64Encoded: string),
              let decrypted = decrypt(data)
        else { return "" }

        return String(data: decrypted, encoding: .utf8) ?? ""
    }

    public func decrypt(_ data: Data) -> Data? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decodedData = try AES.GCM.open(sealedBox, using: symmetricKey)

            return decodedData
        } catch {
            logError?("error: '\(error)'")
        }
        return nil
    }
}
