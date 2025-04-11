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
    var deleteAction: (() -> Void)?
    
    // MARK: - UI Components
    private let colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let selectionIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
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
    
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.red.withAlphaComponent(0.8)
        button.layer.cornerRadius = 12
        button.isHidden = true
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
    
    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(selectionIndicatorView)
        contentView.addSubview(colorView)
        contentView.addSubview(addButton)
        contentView.addSubview(nameLabel)
        contentView.addSubview(hexLabel)
        contentView.addSubview(deleteButton)
        
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
        
        deleteButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-8)
            make.trailing.equalToSuperview().offset(8)
            make.width.height.equalTo(24)
        }
        
        // 삭제 버튼 액션 설정
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        // 기본 상태는 일반 셀
        addButton.isHidden = true
        selectionIndicatorView.isHidden = true
        deleteButton.isHidden = true
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
    
    private var shouldShowDeleteButton = false

    func showDeleteButton(_ show: Bool) {
        shouldShowDeleteButton = show
        
        // 추가 버튼 셀이 아닌 경우에만 삭제 버튼 표시
        if !isAddButton {
            deleteButton.isHidden = !show
        } else {
            deleteButton.isHidden = true
        }
    }
    
    @objc private func deleteButtonTapped(_ sender: UIButton) {
        // 이벤트 버블링 방지
        sender.isUserInteractionEnabled = false
        
        // 애니메이션으로 셀 축소
        UIView.animate(withDuration: 0.2, animations: {
            self.contentView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.contentView.alpha = 0
        }) { [weak self] _ in
            guard let self = self else { return }
            // 액션 콜백 호출 (여기서 실제 삭제 발생)
            self.deleteAction?()
        }
    }
    
    
    
    func setInteractionEnabled(_ enabled: Bool) {
        isUserInteractionEnabled = enabled
        // 시각적 피드백을 위해 편집 모드에서는 기본 팔레트 셀을 약간 흐리게 표시
        if !enabled && !isAddButton {
            contentView.alpha = 0.7
        } else {
            contentView.alpha = 1.0
        }
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
        
        // 중요: 재사용 시에도 삭제 버튼 상태 유지
        deleteButton.isHidden = !shouldShowDeleteButton
        
        // 기본 상태 복원
        contentView.alpha = 1.0
        contentView.backgroundColor = .white
    }
}



