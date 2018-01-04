import XCTest
@testable import memento

class mementoTests: XCTestCase {

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
        
    }

}
