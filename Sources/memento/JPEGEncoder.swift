import Foundation
import Clibavcodec

final public class JPEGEncoder {
    
    fileprivate var codec: AVCodec
    fileprivate var context: AVCodecContext
    fileprivate var contextPtr: UnsafeMutablePointer<AVCodecContext>?
    
    fileprivate var decodeContext: DecodeContext
    
    public init(decodeContext: DecodeContext) {
        avcodec_register_all()
        self.codec           = avcodec_find_encoder(AV_CODEC_ID_MJPEG).pointee
        self.contextPtr      = avcodec_alloc_context3(&self.codec)
        self.context         = self.contextPtr!.pointee
        self.decodeContext   = decodeContext
        
        self.context.pix_fmt             = AV_PIX_FMT_YUVJ420P
        self.context.color_range         = AVCOL_RANGE_JPEG
        self.context.height              = decodeContext.codecContext.height
        self.context.width               = decodeContext.codecContext.width
        self.context.sample_aspect_ratio = decodeContext.codecContext.sample_aspect_ratio
        self.context.time_base           = AVRational(num: 1, den: 25)
        self.context.compression_level   = 100
        self.context.thread_count        = 1
        self.context.flags2              = 0
        self.context.bit_rate            = 80000000
        avcodec_open2(&self.context, &self.codec, nil)
    }
    
    final public func encode(with vFrame: AVFrame) -> Data? {
        guard vFrame.format == AV_PIX_FMT_YUV420P.rawValue else {
            print("Decoded frame needs to be yuv420p")
            return nil
        }
        var frame = vFrame
        
        var ret : Int32 = 0
//        let rgbFramePtr             = av_frame_alloc()
//        rgbFramePtr?.pointee.format = AV_PIX_FMT_YUVJ420P.rawValue
//        rgbFramePtr?.pointee.width  = vFrame.width
//        rgbFramePtr?.pointee.height = vFrame.height
        
//        let swsContext = sws_getContext(vFrame.width, vFrame.height, decodeContext.codecContext.pix_fmt,
//                                        vFrame.width, vFrame.height, AV_PIX_FMT_YUVJ420P,
//                                        SWS_BILINEAR, nil, nil, nil)
//
        
//        //// Get pointers to the input data
//        var dataPointers: [UnsafePointer<UInt8>?] = []
//        let mir = Mirror(reflecting: vFrame.data)
//        for child in mir.children {
//            if let value = child.value as? UnsafeMutablePointer<UInt8> {
//                dataPointers.append(UnsafePointer(value))
//            }
//        }
//
//        //// Get points to the linesizes
//        var lineSizes: [Int32] = []
//        let lmir = Mirror(reflecting: vFrame.linesize)
//        for child in lmir.children {
//            if let value = child.value as? Int32 {
//                if value > 0 {
//                    lineSizes.append(value)
//                }
//            }
//        }
//
//        let srcData  = UnsafePointer(dataPointers)
//        let srcLines = UnsafePointer(lineSizes)
//        var dstData = Array<UnsafeMutablePointer<UInt8>?>(repeating: nil, count: 4)
//        var dstLines: Int32 = 0
//
//        ret = av_image_alloc(&dstData, &dstLines, vFrame.width, vFrame.height, AV_PIX_FMT_YUVJ420P, 1)
//        if ret < 0 {
//            print("Encoding failed (av_image_alloc) dst:", ret)
//            return nil
//        }
//        let dstBufSize = ret
//
//        ret = sws_scale(swsContext, srcData, srcLines, 0, vFrame.height, dstData, &dstLines)
//        if ret <= 0 {
//            print("Encoding failed (sws_scale):", ret)
//            return nil
//        }
        
        ret = avcodec_send_frame(&self.context, &frame)
        if ret < 0 {
            print("Encoding failed (avcodec_send_frame):", ret)
            return nil
        }

        var packetPtr = av_packet_alloc()
        var packet    = packetPtr!.pointee
        ret = avcodec_receive_packet(&self.context, &packet)
        if ret < 0 {
            print("Encoding failed (avcodec_receive_packet):", ret)
            return nil
        }

        let bytes = Array(UnsafeBufferPointer(start: packet.data, count: Int(packet.size)))
        print(packet)

        av_packet_free(&packetPtr)

        return Data(bytes: bytes)
    
    }
    
    deinit {
        avcodec_free_context(&self.contextPtr)
    }
    
}
