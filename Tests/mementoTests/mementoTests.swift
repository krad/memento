import XCTest
@testable import memento

class mementoTests: XCTestCase {

    func test_that_we_can_decode_an_h264_encoded_iframe() {
        
        let fixturesURL = URL(fileURLWithPath: fixturesPath)
        let iFrameURL   = fixturesURL.appendingPathComponent("test.264")
        let iFrameData = try? Data(contentsOf: iFrameURL)
        XCTAssertNotNil(iFrameData)
        
        let iFramePayload =  Array<UInt8>(iFrameData!)

        let decoder = H264Decoder() { img in
            
        }
        decoder.decode(iFramePayload)
        
    }

}
