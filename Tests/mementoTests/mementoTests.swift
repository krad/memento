import XCTest
@testable import memento

class mementoTests: XCTestCase {

    func test_that_we_can_decode_an_h264_encoded_iframe() {
        
        let fixturesURL = URL(fileURLWithPath: fixturesPath)
        let iFrameURL   = fixturesURL.appendingPathComponent("0.h264")
        let iFrameData = try? Data(contentsOf: iFrameURL)
        XCTAssertNotNil(iFrameData)

        let decoder = H264Decoder()
        decoder.decode(iFrameData!)
        
    }

}
