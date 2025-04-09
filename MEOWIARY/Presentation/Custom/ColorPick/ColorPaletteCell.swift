//
//  ColorPaletteCell.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/10/25.
//

import UIKit
import SnapKit

// MARK: - ColorPaletteCell
class ColorPaletteCell: UICollectionViewCell {
    
    // MARK: - Properties
    var isAddButton = false
    
    // MARK: - UI Components
    private let colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .systemPurple
        button.backgroundColor = UIColor.systemGray6
        button.layer.cornerRadius = 8
        button.isUserInteractionEnabled = false // 셀 자체가 탭 핸들링
        return button
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10)
        label.textColor = .darkGray
        label.textAlignment = .center
        return label
    }()
    
    private let hexLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 8)
        label.textColor = .gray
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isSelected: Bool {
        didSet {
            updateSelectionState()
        }
    }
    
    private func setupUI() {
        contentView.addSubview(colorView)
        contentView.addSubview(addButton)
        contentView.addSubview(nameLabel)
        contentView.addSubview(hexLabel)
        
        colorView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(colorView.snp.width)
        }
        
        addButton.snp.makeConstraints { make in
            make.edges.equalTo(colorView)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(colorView.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
        }
        
        hexLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview()
        }
        
        // 기본 상태는 일반 셀
        addButton.isHidden = true
    }
    
    func configure(with color: UIColor, name: String, hexCode: String) {
        colorView.backgroundColor = color
        nameLabel.text = name
        hexLabel.text = "#\(hexCode)"
        
        addButton.isHidden = true
        colorView.isHidden = false
    }
    
    func configureAsAddButton() {
        addButton.isHidden = false
        colorView.isHidden = true
        
        nameLabel.text = "추가"
        hexLabel.text = ""
    }
    
    private func updateSelectionState() {
        
        guard !isAddButton else { return }
        
        if isSelected {
            // 선택 상태 시각화를 더 명확하게 변경
            contentView.layer.borderWidth = 3
            contentView.layer.borderColor = UIColor.systemBlue.cgColor
            contentView.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.3)
        } else {
            contentView.layer.borderWidth = 0
            contentView.backgroundColor = .clear
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        colorView.backgroundColor = nil
        nameLabel.text = nil
        hexLabel.text = nil
        isSelected = false
        contentView.layer.borderWidth = 0
        contentView.backgroundColor = .clear
    }
}



