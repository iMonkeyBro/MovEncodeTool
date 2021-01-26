//
//  ViewController.swift
//  MovEncodeTool
//
//  Created by 刘超群 on 2021/1/26.
//

import UIKit

class ViewController: UIViewController {
    
    private lazy var chooseVideoBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("选择视频", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.frame = CGRect(x: 100, y: 100, width: 100, height: 20)
        btn.addTarget(self, action: #selector(chooseVideo), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(chooseVideoBtn)
    }
    
    @objc private func chooseVideo() {
        guard let picker: TZImagePickerController = TZImagePickerController(maxImagesCount: 1, delegate: self) else { return }
        picker.allowPickingOriginalPhoto = false;
        picker.allowPickingVideo = true;
        picker.allowPickingImage = false;
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true, completion: nil)
    }
}

extension ViewController: TZImagePickerControllerDelegate {
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingVideo coverImage: UIImage!, sourceAssets asset: PHAsset!) {
        MovEncodeTool.convertMovToMp4(from: asset, exportPresetQuality: .highest) { (mp4Url, mp4Data) in
            print("转换成功--\(mp4Url)")
        } errorClosure: { (errorMsg) in
            print(errorMsg)
        }

    }
}

