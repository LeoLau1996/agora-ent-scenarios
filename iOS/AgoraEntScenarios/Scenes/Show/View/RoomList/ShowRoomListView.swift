//
//  RoomListView.swift
//  AgoraEntScenarios
//
//  Created by FanPengpeng on 2022/11/3.
//

import UIKit

class ShowRoomListView: UIView {
    
    var clickCreateButtonAction: (()->())?
    var collectionView: UICollectionView!
    var emptyView: ShowEmptyView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        createSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createSubviews(){
        // 列表
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        let itemWidth = (Screen.width - 15 - 20 * 2) * 0.5
        layout.itemSize = CGSize(width: itemWidth, height: 234.0 / 160.0 * itemWidth)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(ShowRoomListCell.self, forCellWithReuseIdentifier: NSStringFromClass(ShowRoomListCell.self))
        collectionView.delegate = self
        collectionView.dataSource = self
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top:  98, left: 0, bottom: 0, right: 0))
        }
        
        // 空列表
        emptyView = ShowEmptyView()
        emptyView.isHidden = true
        collectionView.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(156)
        }
        
        // 创建房间按钮
        let btnHeight: CGFloat = 48
        let createButton = UIButton(type: .custom)
        createButton.setTitleColor(.white, for: .normal)
        createButton.setTitle("room_list_create_room".show_localized, for: .normal)
        createButton.setImage(UIImage.show_sceneImage(name: "show_create_add"), for: .normal)
        createButton.imageEdgeInsets(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 5))
        createButton.titleEdgeInsets(UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0))
        createButton.backgroundColor = .show_btn_bg
        createButton.titleLabel?.font = .show_btn_title
        createButton.layer.cornerRadius = btnHeight * 0.5
        createButton.layer.masksToBounds = true
        createButton.addTarget(self, action: #selector(didClickCreateButton), for: .touchUpInside)
        addSubview(createButton)
        createButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-34)
            make.height.equalTo(btnHeight)
            make.width.equalTo(195)
        }
    }

    // 点击创建按钮
    @objc private func didClickCreateButton(){
       clickCreateButtonAction?()
    }
}


extension ShowRoomListView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ShowRoomListCell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(ShowRoomListCell.self), for: indexPath) as! ShowRoomListCell
        return cell
    }
    
}
