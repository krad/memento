import Foundation
import Clibavcodec

final public class JPEGEncoder {
    
    fileprivate var codec: AVCodec
    fileprivate var context: AVCodecContext
    fileprivate var decodeContext: DecodeContext
    
    public init(decodeContext: DecodeContext) {
        avcodec_register_all()
        self.codec           = avcodec_find_encoder(AV_CODEC_ID_JPEG2000).pointee
        self.context         = avcodec_alloc_context3(&self.codec).pointee
        self.decodeContext   = decodeContext
        
        self.context.pix_fmt             = decodeContext.codecContext.pix_fmt
        self.context.height              = decodeContext.codecContext.height
        self.context.width               = decodeContext.codecContext.width
        self.context.sample_aspect_ratio = decodeContext.codecContext.sample_aspect_ratio
        self.context.time_base           = AVRational(num: 1, den: 25)
        self.context.compression_level   = 100
        self.context.thread_count        = 1
        self.context.flags2              = 0
        self.context.bit_rate            = 80000000
        self.context.rc_min_rate         = self.context.bit_rate
        self.context.rc_max_rate         = self.context.rc_min_rate

        avcodec_open2(&self.context, &self.codec, nil)
    }
    
    public func encode(with vFrame: AVFrame) -> Data? {
        var frame = vFrame
        var ret: Int32  = 0
        
        ret = avcodec_send_frame(&self.context, &frame)
        if ret < 0 {
            print("Encoding failed (avcodec_send_frame):", ret)
            return nil
        }
        
        var packet = av_packet_alloc().pointee
        ret = avcodec_receive_packet(&self.context, &packet)
        if ret < 0 {
            print("FUCK")
            return nil
        }
        
        let bytes = Array(UnsafeBufferPointer(start: packet.data, count: Int(packet.size)))
        return Data(bytes: bytes)
    
    }
    
}
