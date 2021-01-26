//
//  MovEncodeTool.swift
//  MovEncodeTool
//
//  Created by 刘超群 on 2021/1/26.
//

import Foundation
import Photos

/// Mov视频格式编码工具
public final class MovEncodeTool {
    
    public typealias ResultClosure = (_ mp4FileUrl: URL, _ mp4Data: Data) -> ()
    public typealias ErrorClosure = (_ errorMsg: String) -> ()
    
    
    /// mov转码mp4
    /// - Parameters:
    ///   - phAsset: PHAsset mov资源
    ///   - exportQuality: 预设输出质量
    ///   - resultClosure: 转码成功文件信息
    ///   - errorClosure: 转码失败信息
    public static func convertMovToMp4(from phAsset: PHAsset,
                                exportPresetQuality exportQuality: MovEncodeExportPresetQuality,
                                resultClosure:@escaping ResultClosure,
                                errorClosure:@escaping ErrorClosure) {
        print(MovEncodeTool.getVideoInfo(phAsset) ?? "")
        let options = PHVideoRequestOptions()
        options.version = .current
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        let manager = PHImageManager.default()
        // PHAsset转AVURLAsset
        manager.requestAVAsset(forVideo: phAsset, options: options) { (asset, audioMix, info) in
            guard let urlAsset: AVURLAsset = asset as? AVURLAsset else {
                errorClosure("resource type error")
                return
            }
            MovEncodeTool.convertMovToMp4(from: urlAsset, exportPresetQuality: exportQuality, resultClosure: resultClosure, errorClosure: errorClosure)
        }
    }
    
    /// mov转码mp4
    /// - Parameters:
    ///   - urlAsset: AVURLAsset mov资源
    ///   - exportQuality: 预设输出质量
    ///   - resultClosure: 转码成功文件信息
    ///   - errorClosure: 转码失败信息
    public static func convertMovToMp4(from urlAsset: AVURLAsset,
                                exportPresetQuality exportQuality: MovEncodeExportPresetQuality,
                                resultClosure:@escaping ResultClosure,
                                errorClosure:@escaping ErrorClosure) {
        let avAsset = AVURLAsset(url: urlAsset.url)
        // 处理输出预设
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: avAsset)
        guard compatiblePresets.contains(MovEncodeTool.getAVAssetExportPresetQuality(exportQuality)) == true else {
            errorClosure("没有匹配的预设")
            return
        }
        // 处理路径
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!.appending("/Cache/VideoData")
        let fileManager = FileManager.default
        let isDirExist = fileManager.fileExists(atPath: path)
        if isDirExist == false {
            do {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("文件夹创建失败\(path)")
                errorClosure("文件夹创建失败\(path)")
                return
            }
            print("创建文件夹成功\(path)")
        }
        // 拼接文件最终路径
        let dateFormat = DateFormatter()
        dateFormat.locale = Locale(identifier: "zh_CN")
        dateFormat.dateFormat = "yyyyMMddHHmmss"
        let dateStr = dateFormat.string(from: Date())
        let resultPath = path.appending("\(dateStr).mp4")
        print("resultPath == \(resultPath)")
        // 格式转换
        guard let exportSession: AVAssetExportSession = AVAssetExportSession(asset: avAsset, presetName: MovEncodeTool.getAVAssetExportPresetQuality(exportQuality)) else {
            errorClosure("AVAssetExportSession创建失败")
            return
        }
        exportSession.outputURL = URL(fileURLWithPath: resultPath)
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously {
            // 转换结果处理
            switch (exportSession.status) {
            case .completed:
                do {
                    let mp4Data = try Data(contentsOf: exportSession.outputURL!)
                    resultClosure(exportSession.outputURL!, mp4Data)
                } catch  {
                    errorClosure("mp4Data创建失败")
                }
            case .exporting:
                errorClosure("exporting")
            case .cancelled:
                errorClosure("cancelled")
            case .unknown:
                errorClosure("unknown")
            case .waiting:
                errorClosure("waiting")
            case .failed:
                errorClosure("failed")
            @unknown default:
                errorClosure("unknown default")
            }
        }
    }
}

// MARK: - Public Func
public extension MovEncodeTool {
    
    /// 获取视频信息
    /// - Parameter asset: PHAsset相册视频文件
    /// - Returns: 视频信息
    static func getVideoInfo(_ asset: PHAsset) -> Dictionary<String, String>? {
        guard let resource: PHAssetResource = PHAssetResource.assetResources(for: asset).first else {return nil}
        var resourceArr: [String]
        if #available(iOS 13.0, *) {
            let temStr = resource.description.replacingOccurrences(of: " - ", with: " ").replacingOccurrences(of: ": ", with: "=").replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "").replacingOccurrences(of: ", ", with: " ")
            resourceArr = temStr.components(separatedBy: " ")
            resourceArr.removeFirst()
            resourceArr.removeFirst()
        } else {
            let temStr = resource.description.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "").replacingOccurrences(of: ", ", with: " ")
            resourceArr = temStr.components(separatedBy: " ")
            resourceArr.removeFirst()
            resourceArr.removeFirst()
        }
        var videoInfo: [String: String] = [:]
        resourceArr.forEach {
            let temArr = $0.components(separatedBy: "=")
            if temArr.count > 2 {
                videoInfo[temArr[0]] = temArr[1]
            }
        }
        videoInfo["duration"] = (asset.duration as NSNumber).description
        return videoInfo
    }
}

// MARK: - Private Func
private extension MovEncodeTool {
    static func getAVAssetExportPresetQuality(_ exportPreset: MovEncodeExportPresetQuality) -> String {
        switch exportPreset {
        case .low:
            return AVAssetExportPresetLowQuality
        case .medium:
            return AVAssetExportPresetMediumQuality
        case .highest:
            return AVAssetExportPresetHighestQuality
        case .dpi640x480:
            return AVAssetExportPreset640x480
        case .dpi960x540:
            return AVAssetExportPreset960x540
        case .dpi1280x720:
            return AVAssetExportPreset1280x720
        case .dpi1920x1080:
            return AVAssetExportPreset1920x1080
        case .dpi3840x2160:
            return AVAssetExportPreset3840x2160
        }
    }
}

// MARK: - MovEncodeExportPresetQuality
public enum MovEncodeExportPresetQuality {
    case low
    case medium
    case highest
    case dpi640x480
    case dpi960x540
    case dpi1280x720
    case dpi1920x1080
    case dpi3840x2160
}
