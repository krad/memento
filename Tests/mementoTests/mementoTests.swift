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
        
        do {
            /////////////////////////
            let result = try smokeTest(sps: "sps.b64", pps: "pps.b64", idr: "idr.b64")
            XCTAssertNotNil(result)

            let url = URL(fileURLWithPath: "/tmp/1", isDirectory: false)
            try result?.write(to: url)
            
            /////////////////////////
            let resultA = try smokeTest(sps: "spsA.b64", pps: "ppsA.b64", idr: "idrA.b64")
            XCTAssertNotNil(resultA)

            let url2 = URL(fileURLWithPath: "/tmp/2", isDirectory: false)
            try resultA?.write(to: url2)

            /////////////////////////
            let resultB = try smokeTest(sps: "spsB.b64", pps: "ppsB.b64", idr: "idrB.b64")
            XCTAssertNotNil(resultB)

            let url3 = URL(fileURLWithPath: "/tmp/3", isDirectory: false)
            try resultB?.write(to: url3)

            /////////////////////////
            let resultC = try smokeTest(sps: "spsC.b64", pps: "ppsC.b64", idr: "idrC.b64")
            XCTAssertNotNil(resultC)

            let url4 = URL(fileURLWithPath: "/tmp/4", isDirectory: false)
            try resultC?.write(to: url4)

            
        } catch let err {
            print(err)
            XCTFail("Failed to decode data")
        }
        
    }
    
    func smokeTest(sps: String, pps: String, idr: String) throws -> Data? {
        let fixturesURL = URL(fileURLWithPath: fixturesPath)
        let spsURL      = fixturesURL.appendingPathComponent(sps)
        let ppsURL      = fixturesURL.appendingPathComponent(pps)
        let idrURL      = fixturesURL.appendingPathComponent(idr)

        let spsStr      = try? String(contentsOf: spsURL)
        let ppsStr      = try? String(contentsOf: ppsURL)
        let idrStr      = try? String(contentsOf: idrURL)
        
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
        let result = try m.decode(req)
        return result
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
