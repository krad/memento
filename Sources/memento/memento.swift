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
}

final public class Memento {
    
    private var sps: [UInt8]?
    private var pps: [UInt8]?
    
    private let h264Decoder = H264Decoder()
    
    public init() { }
    
    final public func set(sps: [UInt8], pps: [UInt8]) {
        self.sps = sps
        self.pps = pps
    }
    
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
    
    final public func decode(keyframe: [UInt8]) throws -> Data? {
        if let sps = self.sps, let pps = self.pps {
//            var payload: [UInt8] = delimiter + [0x67] + sps
//            payload += delimiter + [0x68] + pps
//            payload += delimiter + keyframe
            
            var payload: [UInt8] = delimiter + sps
            payload += delimiter + pps
            payload += delimiter + keyframe
            
            if let decContext = self.h264Decoder.decode(payload) {
                let jpgEncoder = JPEGEncoder(decodeContext: decContext)
                if let jpeg    = jpgEncoder.encode(with: decContext.frame) {
                    return jpeg
                }
            }
        }
        throw MementoError.failedToEncode
    }
    
}

/// FIXME: Make this more robust
func buildPayload(sps: [UInt8], pps: [UInt8], frame: [UInt8]) -> [UInt8] {
    var payload: [UInt8] = delimiter + sps
    payload += delimiter + pps
    payload += delimiter + frame
    return payload
}
