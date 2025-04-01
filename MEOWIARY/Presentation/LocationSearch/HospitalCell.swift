//
//  HospitalCell.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/1/25.
//

import UIKit
import SnapKit

final class HospitalCell: UITableViewCell {
  
  // MARK: - UI Components
  private let containerView: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    return view
  }()
  
  private let hospitalNameLabel: UILabel = {
    let label = UILabel()
    label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.medium)
    label.textColor = DesignSystem.Color.Tint.text.inUIColor()
    return label
  }()
  
  private let addressLabel: UILabel = {
    let label = UILabel()
    label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.small)
    label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
    return label
  }()
  
  private let phoneLabel: UILabel = {
    let label = UILabel()
    label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.small)
    label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
    return label
  }()
  
  private let distanceLabel: UILabel = {
    let label = UILabel()
    label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.small)
    label.textColor = DesignSystem.Color.Tint.main.inUIColor()
    label.textAlignment = .right
    return label
  }()
  
  // MARK: - Initialization
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Setup
  private func setupUI() {
    selectionStyle = .none
    
    contentView.addSubview(containerView)
    containerView.addSubview(hospitalNameLabel)
    containerView.addSubview(addressLabel)
    containerView.addSubview(phoneLabel)
    containerView.addSubview(distanceLabel)
    
    containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(UIEdgeInsets(top: 5, left: DesignSystem.Layout.standardMargin, bottom: 5, right: DesignSystem.Layout.standardMargin))
    }
    
    hospitalNameLabel.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(8)
      make.leading.equalToSuperview()
      make.trailing.equalTo(distanceLabel.snp.leading).offset(-DesignSystem.Layout.smallMargin)
    }
    
    addressLabel.snp.makeConstraints { make in
      make.top.equalTo(hospitalNameLabel.snp.bottom).offset(4)
      make.leading.equalToSuperview()
      make.trailing.equalTo(distanceLabel.snp.leading).offset(-DesignSystem.Layout.smallMargin)
    }
    
    phoneLabel.snp.makeConstraints { make in
      make.top.equalTo(addressLabel.snp.bottom).offset(2)
      make.leading.equalToSuperview()
      make.bottom.equalToSuperview().offset(-8)
    }
    
    distanceLabel.snp.makeConstraints { make in
      make.centerY.equalToSuperview()
      make.trailing.equalToSuperview()
      make.width.equalTo(60)
    }
  }
  
  // MARK: - Configuration
  func configure(with hospital: Hospital) {
    hospitalNameLabel.text = hospital.name
    addressLabel.text = hospital.address
    phoneLabel.text = hospital.phone
    distanceLabel.text = hospital.distance
  }
}
