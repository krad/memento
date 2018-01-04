import Foundation
import Clibavcodec


final public class H264Decoder {

    fileprivate let IN_BUF_SIZE = 4096
    
    fileprivate var codec: AVCodec
    fileprivate var context: AVCodecContext
    fileprivate var parser: AVCodecParserContext
    fileprivate var packet: AVPacket
    fileprivate var picture: AVFrame
    
    fileprivate var decodeCallback: (Data) -> Void
    
    public init(decodeCallback: @escaping (Data) -> Void) {
        avcodec_register_all()
        self.decodeCallback = decodeCallback
        self.codec          = avcodec_find_decoder(AV_CODEC_ID_H264).pointee
        self.parser         = av_parser_init(Int32(self.codec.id.rawValue)).pointee
        self.context        = avcodec_alloc_context3(&self.codec).pointee
        self.packet         = av_packet_alloc().pointee
        self.picture        = av_frame_alloc().pointee
        
        avcodec_open2(&self.context, &self.codec, nil)
    }

    func decode(_ payload: [UInt8]) {
        var safePayload = payload
        
        var cnt: Int32 = 0
        while cnt < payload.count {
            
            var ptr: UnsafeMutablePointer<UInt8>? = UnsafeMutablePointer.allocate(capacity: 4096)
            var size: Int32 = 0

            var ret = av_parser_parse2(&parser,
                                       &context,
                                       &ptr,
                                       &size,
                                       &safePayload,
                                       Int32(payload.count),
                                       0x80,
                                       0x80,
                                       0)

            if size > 0 {
                packet.data = ptr
                packet.size = size

                ret = avcodec_send_packet(&context, &self.packet)
                if ret < 0 {
                    print("avcodec_send_packet problem")
                    continue
                }
                
                ret = avcodec_receive_frame(&self.context, &self.picture)
                if ret < 0 {
                    print(self.picture)
                    print("error decoding, avcodec_receive_frame", ret)
                    continue
                }
                
                print(picture)

                cnt += 1
            } else {
                cnt += ret-1
            }

            
        }
        
    }
    
}
