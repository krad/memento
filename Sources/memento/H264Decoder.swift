import Foundation

import Clibavcodec

public struct DecodeContext {
    var codecContext: AVCodecContext
    var frame: AVFrame
}

final public class H264Decoder {
    
    fileprivate var codec: AVCodec
    
    fileprivate var contextPtr: UnsafeMutablePointer<AVCodecContext>?
    fileprivate var context: AVCodecContext?

    fileprivate var parserPtr: UnsafeMutablePointer<AVCodecParserContext>?
    fileprivate var parser: AVCodecParserContext

    fileprivate var packetPtr: UnsafeMutablePointer<AVPacket>?
    fileprivate var packet: AVPacket
    
    public init() {
        avcodec_register_all()
        self.codec      = avcodec_find_decoder(AV_CODEC_ID_H264).pointee
        
        self.parserPtr  = av_parser_init(Int32(self.codec.id.rawValue))
        self.parser     = self.parserPtr!.pointee

        self.contextPtr = avcodec_alloc_context3(&self.codec)
        self.context    = self.contextPtr?.pointee
        
        self.packetPtr  = av_packet_alloc()
        self.packet     = packetPtr!.pointee
        avcodec_open2(&self.context!, &self.codec, nil)
    }
    
    final public func decode(_ payload: [UInt8]) -> DecodeContext? {
        var safePayload = payload
        
        var cnt: Int32 = 0
        while cnt < payload.count {
            
            var ptr: UnsafeMutablePointer<UInt8>? = UnsafeMutablePointer.allocate(capacity: 4096)
            var size: Int32 = 0
            
            var ret = av_parser_parse2(&parser,
                                       &context!,
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
                
                ret = avcodec_send_packet(&context!, &self.packet)
                if ret < 0 {
                    print("avcodec_send_packet problem")
                    continue
                }
                
                let picturePtr = av_frame_alloc()
                var picture    = picturePtr!.pointee
                ret = avcodec_receive_frame(&self.context!, &picture)
                if ret < 0 {
                    print("error decoding, (avcodec_receive_frame)", ret)
                    continue
                } else {
                    return DecodeContext(codecContext: self.context!, frame: picture)
                }
                
            } else {
                cnt += ret-1
            }
            
            
        }
        
        return nil
    }
    
    deinit {
//        avcodec_close(contextPtr)
//        /// free the packet
        let pPtr = ptrFromAddress(p: &self.packetPtr)
        av_packet_free(pPtr)

        /// free the context
        let cPtr = ptrFromAddress(p: &self.contextPtr)
        avcodec_free_context(cPtr)

        /// close the parser
        av_parser_close(self.parserPtr)
    }
    
}

func ptrFromAddress<T>(p:UnsafeMutablePointer<T>) -> UnsafeMutablePointer<T> {
    return p
}

