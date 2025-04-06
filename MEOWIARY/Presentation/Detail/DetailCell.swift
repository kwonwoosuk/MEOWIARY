//
//  DetailCell.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/6/25.
//

import UIKit
import SnapKit

class DetailCell: UICollectionViewCell {
  let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 10 // 모서리 둥글게 설정
    imageView.layer.borderWidth = 1
    imageView.layer.borderColor = UIColor.lightGray.cgColor
    return imageView
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.addSubview(imageView)
    imageView.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(10) // 이미지뷰에 약간의 여백 추가
    }
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    imageView.image = nil
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
