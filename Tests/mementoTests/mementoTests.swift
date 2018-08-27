import XCTest
@testable import memento

class mementoTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    func test_that_we_can_decode_an_h264_encoded_iframe_and_produce_a_jpg() {
        
        let fixturesURL = URL(fileURLWithPath: fixturesPath)
        let iFrameURL   = fixturesURL.appendingPathComponent("test.264")
        let iFrameData = try? Data(contentsOf: iFrameURL)
        XCTAssertNotNil(iFrameData)
        
        let iFramePayload =  Array<UInt8>(iFrameData!)

        let decoder    = H264Decoder()
        let decContext = decoder.decode(iFramePayload)
        XCTAssertNotNil(decContext)
        
        XCTAssertEqual(480, decContext?.frame.width)
        XCTAssertEqual(272, decContext?.frame.height)
        
        let jpgEncoder = JPEGEncoder(decodeContext: decContext!)
        let jpeg       = jpgEncoder.encode(with: decContext!.frame)
        XCTAssertNotNil(jpeg)
        XCTAssertGreaterThan(jpeg!.count, 0)
        
        let url = URL.init(fileURLWithPath: "/tmp/0.jpg")
        try? jpeg?.write(to: url)
        
    }
    
    func test_that_we_can_decode_an_h264_encoded_frame_from_base64() {
        
        let fixturesURL = URL(fileURLWithPath: fixturesPath)
        let spsURL      = fixturesURL.appendingPathComponent("sps.b64")
        let ppsURL      = fixturesURL.appendingPathComponent("pps.b64")
        let idrURL      = fixturesURL.appendingPathComponent("idr.b64")
        let spsStr      = try? String(contentsOf: spsURL)
        let ppsStr      = try? String(contentsOf: ppsURL)
        let idrStr      = try? String(contentsOf: idrURL)
        
//        let spsData = Data(base64Encoded: spsStr!, options: .ignoreUnknownCharacters)
//        let ppsData = Data(base64Encoded: ppsStr!, options: .ignoreUnknownCharacters)
//        let idrData = Data(base64Encoded: idrStr!, options: .ignoreUnknownCharacters)
//        XCTAssertNotNil(spsData)
//        XCTAssertNotNil(ppsData)
//        XCTAssertNotNil(idrData)
//        let spsPayload = [UInt8](spsData!)
//        let ppsPayload = [UInt8](ppsData!)
//        let idrPayload = [UInt8](idrData!)
        
        
        let config = ThumbnailConfig(width: 100,
                                     height: 100,
                                     rotate: .none,
                                     fitMode: .preserve,
                                     flipV: false,
                                     flipH: false)
        
        let req    = Base64EncodedThumbnailRequest(sps: spsStr,
                                                   pps: ppsStr,
                                                   payload: idrStr!,
                                                   config: config)
        
        let m      = Memento()
        let result = try? m.decode(req)
        XCTAssertNotNil(result as? Data)
    }
    
    
    static var allTests = [
        ("Decoding h264 and producing a jpeg", test_that_we_can_decode_an_h264_encoded_iframe_and_produce_a_jpg),
    ]


}

extension mementoTests: MementoProtocol {
    func wroteJPEG(to url: URL) {
        print(url)
        print(#function)
    }
    
    func failedToWriteJPEG(error: Error) {
        print(#function)
    }
}
