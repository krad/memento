import Foundation

protocol MementoProtocol {
    func wroteJPEG(to url: URL)
    func failedToWriteJPEG(error: Error)
}

final public class Memento {
    
    private let outputDir: URL
    
    private let delimiter: [UInt8] = [0x0, 0x0, 0x0, 0x1]
    private var sps: [UInt8]?
    private var pps: [UInt8]?
    
    private let h264Decoder = H264Decoder()
    private var decodedFrameCnt = 0
    private var delegate: MementoProtocol
    
    init(outputDir: URL, delegate: MementoProtocol) {
        self.outputDir = outputDir
        self.delegate  = delegate
    }
    
    func set(sps: [UInt8], pps: [UInt8]) {
        self.sps = sps
        self.pps = pps
    }
    
    func decode(keyframe: [UInt8]) {
        if let sps = self.sps, let pps = self.pps {
            var payload: [UInt8] = delimiter + [0x67] + sps
            payload += delimiter + [0x68] + pps
            payload += delimiter + keyframe
            
            if let decContext = self.h264Decoder.decode(payload) {
                let jpgEncoder = JPEGEncoder(decodeContext: decContext)
                if let jpeg    = jpgEncoder.encode(with: decContext.frame) {
                    
                    let url = self.outputDir.appendingPathComponent("\(decodedFrameCnt).jpg")
                    do {
                        try jpeg.write(to: url)
                        self.decodedFrameCnt += 1
                        self.delegate.wroteJPEG(to: url)
                    } catch let err {
                        print("Couldn't decode keyframe:", err)
                        self.delegate.failedToWriteJPEG(error: err)
                    }
                    
                }
            }
        }
    }
    
}
