import Foundation

let delimiter: [UInt8] = [0x0, 0x0, 0x0, 0x1]

public protocol MementoProtocol {
    func wroteJPEG(to url: URL)
    func failedToWriteJPEG(error: Error)
}

public enum OutputFormat: String, Codable {
    case jpg = "jpg"
    case png = "png"
}

public enum Rotation: UInt32, Codable {
    case none       = 0
    case ninety     = 90
    case oneEighty  = 180
    case twoSeventy = 270
}

public enum FitMode: String, Codable {
    case preserve   = "preserve"
    case stretch    = "stretch"
    case crop       = "crop"
    case smartcrop  = "smartcrop"
    case pad        = "pad"
}

public struct ThumbnailConfig: Codable {
    var width: UInt32?
    var height: UInt32?
    var rotate: Rotation = .none
    var fitMode: FitMode = .preserve
    var flipV: Bool      = false
    var flipH: Bool      = false
}

public struct ThumbnailEncodeRequest: Codable {
    var sps: [UInt8]?
    var pps: [UInt8]?
    var payload: [UInt8]
}

public struct Base64EncodedThumbnailRequest: Codable {
    var sps: String?
    var pps: String?
    var payload: String
    
    var config: ThumbnailConfig?
    
    var spsBytes: [UInt8]? { return decodeBase64(self.sps) }
    var ppsBytes: [UInt8]? { return decodeBase64(self.pps) }
    var payloadBytes: [UInt8] { return decodeBase64(self.payload)! }
    
    public func debug() -> String {
        return [self.sps, self.pps, self.payload].compactMap { return $0 }.joined(separator: "\n\n\n")
    }
    
}

func decodeBase64(_ key: String?) -> [UInt8]? {
    guard let str = key else { return nil }
    if let data = Data(base64Encoded: str, options: .ignoreUnknownCharacters) {
        return [UInt8](data)
    }
    return nil
}

public enum MementoError: Error {
    case thumbnailEncodeFailed
    case h264DecodeFailed
    case needDecoderConfig
    case failedToEncode
    
    var description: String {
        switch self {
        case .thumbnailEncodeFailed:
            return "Thumbnail Encode Failed"
        case .h264DecodeFailed:
            return "h264 Decode Failed"
        case .needDecoderConfig:
            return "Missing Decoder Config"
        case .failedToEncode:
            return "Failed to encode"
        }
    }
}

final public class Memento {
    
    private let h264Decoder = H264Decoder()
    
    public init() { }
    
    final public func decode(_ req: Base64EncodedThumbnailRequest) throws -> Data? {
        if let sps = req.spsBytes, let pps = req.ppsBytes {
            let payload = buildPayload(sps: sps, pps: pps, frame: req.payloadBytes)
            if let decContext = self.h264Decoder.decode(payload) {
                let jpegEncoder = JPEGEncoder(decodeContext: decContext)
                if let pic = jpegEncoder.encode(with: decContext.frame) {
                    return pic
                } else {
                    throw MementoError.thumbnailEncodeFailed
                }
            } else {
                throw MementoError.h264DecodeFailed
            }
        }
        throw MementoError.needDecoderConfig
    }
        
}

/// FIXME: Make this more robust
func buildPayload(sps: [UInt8], pps: [UInt8], frame: [UInt8]) -> [UInt8] {
    var payload: [UInt8] = delimiter + sps
    payload += delimiter + pps
    payload += delimiter + frame
    return payload
}
