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
    
    private let selectionIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = DesignSystem.Color.Tint.main.inUIColor()
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 3
        view.layer.borderColor = DesignSystem.Color.Tint.main.inUIColor().cgColor
        view.isHidden = true
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
    
    override var isHighlighted: Bool {
        didSet {
            // 하이라이트 상태 처리 (터치 피드백)
            UIView.animate(withDuration: 0.1) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
                self.alpha = self.isHighlighted ? 0.9 : 1.0
            }
        }
    }
    
    
    private func setupUI() {
        contentView.addSubview(selectionIndicatorView)
        contentView.addSubview(colorView)
        contentView.addSubview(addButton)
        contentView.addSubview(nameLabel)
        contentView.addSubview(hexLabel)
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        contentView.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        contentView.layer.shadowOpacity = 0.5
        contentView.layer.masksToBounds = false
        
        selectionIndicatorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
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
        selectionIndicatorView.isHidden = true
    }
    
    func configure(with color: UIColor, name: String, hexCode: String) {
        colorView.backgroundColor = color
        nameLabel.text = name
        hexLabel.text = "#\(hexCode)"
        
        addButton.isHidden = true
        colorView.isHidden = false
        
        // 항상 선택 상태 업데이트
        updateSelectionState()
    }
    
    func configureAsAddButton() {
        addButton.isHidden = false
        colorView.isHidden = true
        
        nameLabel.text = ""
        hexLabel.text = ""
    }
    
    private func updateSelectionState() {
        if isAddButton {
            selectionIndicatorView.isHidden = true
            return
        }
        
        // 선택 상태에 따른 시각적 변화
        selectionIndicatorView.isHidden = !isSelected
        
        // 애니메이션으로 선택 효과 강화
        if isSelected {
            UIView.animate(withDuration: 0.2) {
                self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.transform = .identity
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        colorView.backgroundColor = nil
        nameLabel.text = nil
        hexLabel.text = nil
        isSelected = false
        transform = .identity
        selectionIndicatorView.isHidden = true
        contentView.backgroundColor = .white
    }
}



