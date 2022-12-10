//
//  PrivateParamsVC.swift
//  AgoraEntScenarios
//
//  Created by FanPengpeng on 2022/12/10.
//

import UIKit

class ShowPrivateParamsVC: UIViewController {
    
//    var params: [String]?
    var result: ((_ params: [String]?, _ text: String?)->())?
    
    
    private lazy var headerView: ShowNavigationBar = {
        let headerView = ShowNavigationBar()
        return headerView
    }()
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        return textView
    }()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        textView.becomeFirstResponder()
//        textView.text = params?.joined(separator: ",")
        textView.text = ShowAgoraKitManager.privateParamsText
    }
    
    private func setUpUI(){
        view.backgroundColor = .white
        headerView.title = "Private parameters"
        view.addSubview(headerView)
        headerView.setLeftButtonTarget(self, action: #selector(didClickCloseButton), image: UIImage.show_sceneImage(name: "show_preset_close"))
        let saveButtonItem = ShowBarButtonItem(title: "show_advanced_setting_presetting_save".show_localized, target: self, action: #selector(didClickSaveButton))
        headerView.rightItems = [saveButtonItem]
        
        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(100)
        }
    }
    
    

    @objc private func didClickCloseButton() {
        dismiss(animated: true)
    }
    
    @objc private func didClickSaveButton() {
        dismiss(animated: true)
        guard let text: NSString = textView.text as? NSString else { return }
        let params = text.components(separatedBy: ",")
        result?(params, text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

}
