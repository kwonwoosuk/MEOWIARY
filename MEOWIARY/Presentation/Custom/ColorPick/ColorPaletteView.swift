//
//  ColorPaletteView.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/10/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

// 컬러 팔레트에 대한 모델 정의
struct ColorPalette {
    var id: String
    var name: String
    var color: UIColor
    var hexCode: String
    var isCustom: Bool
    
    // 팔레트를 UserDefaults에 저장하기 위한 Dictionary 변환
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "hexCode": hexCode,
            "isCustom": isCustom
        ]
    }
    
    // UserDefaults에서 불러온 Dictionary에서 팔레트 생성
    static func fromDictionary(_ dict: [String: Any]) -> ColorPalette? {
        guard let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let hexCode = dict["hexCode"] as? String,
              let isCustom = dict["isCustom"] as? Bool else {
            return nil
        }
        
        return ColorPalette(
            id: id,
            name: name,
            color: UIColor(hex: hexCode),
            hexCode: hexCode,
            isCustom: isCustom
        )
    }
}

protocol ColorPaletteViewDelegate: AnyObject {
    func didSelectColor(_ color: UIColor, hexCode: String)
    func didCancelSelection()
}

class ColorPaletteView: BaseView, UIGestureRecognizerDelegate {
    
    // MARK: - Properties
    weak var delegate: ColorPaletteViewDelegate?
    private let disposeBag = DisposeBag()
    private var palettes: [ColorPalette] = []
    private let selectedIndexPathRelay = BehaviorRelay<IndexPath?>(value: nil)
    private var isEditMode = false
    
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "색상 팔레트"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .black
        return label
    }()
    
    private let dividerLine: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "월별 색상 설정"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()
    
    private lazy var colorCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(ColorPaletteCell.self, forCellWithReuseIdentifier: "ColorPaletteCell")
        return collectionView
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("취소", for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 8
        return button
    }()
    
    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("편집", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor(hex: "FF6A6A") // DesignSystem.Color.Tint.main
        button.layer.cornerRadius = 8
        return button
    }()
    
    private let selectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("선택", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor(hex: "FF6A6A") // DesignSystem.Color.Tint.main
        button.layer.cornerRadius = 8
        button.isEnabled = false // 처음에는 비활성화 상태
        button.alpha = 0.5
        button.isHidden = true // 편집 모드에서만 보임
        return button
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("완료", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor(hex: "42A5F5") // DesignSystem.Color.Tint.action
        button.layer.cornerRadius = 8
        button.isHidden = true // 편집 모드에서만 보임
        return button
    }()
    
    // MARK: - Configuration
    
    override func configureHierarchy() {
        addSubview(titleLabel)
        addSubview(dividerLine)
        addSubview(subtitleLabel)
        addSubview(colorCollectionView)
        addSubview(cancelButton)
        addSubview(editButton)
        addSubview(selectButton)
        addSubview(doneButton)
    }
    
    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
        }
        
        dividerLine.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(dividerLine.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
        }
        
        colorCollectionView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(cancelButton.snp.top).offset(-16)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(50)
            make.width.equalTo(self.snp.width).dividedBy(2.2)
        }
        
        editButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(50)
            make.width.equalTo(self.snp.width).dividedBy(2.2)
        }
        
        selectButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(50)
            make.width.equalTo(self.snp.width).dividedBy(2.2)
        }
        
        doneButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(50)
            make.width.equalTo(self.snp.width).dividedBy(2.2)
        }
    }
    
    override func configureView() {
        backgroundColor = .white
        layer.cornerRadius = 16
        
        // 컬렉션뷰 설정
        colorCollectionView.delegate = self
        colorCollectionView.dataSource = self
        
        colorCollectionView.isUserInteractionEnabled = true // 터치 활성화 명시
        colorCollectionView.delaysContentTouches = false // 터치 지연 비활성화
        colorCollectionView.canCancelContentTouches = true // 터치 취소 허용
        
        // 버튼 액션 설정
        cancelButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.delegate?.didCancelSelection()
            })
            .disposed(by: disposeBag)
        
        // 편집 버튼 액션
        editButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.toggleEditMode(true)
            })
            .disposed(by: disposeBag)
        
        // 완료 버튼 액션
        doneButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.toggleEditMode(false)
            })
            .disposed(by: disposeBag)
        
        selectedIndexPathRelay
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if let indexPath = indexPath, indexPath.row < self.palettes.count {
                        self.selectButton.isEnabled = true
                        self.selectButton.alpha = 1.0
                    } else {
                        self.selectButton.isEnabled = false
                        self.selectButton.alpha = 0.5
                    }
                    self.updateSelectedCell(indexPath: indexPath)
                }
            })
            .disposed(by: disposeBag)
        
        selectButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self,
                      let indexPath = self.selectedIndexPathRelay.value,
                      indexPath.row < self.palettes.count else { return }
                let selectedPalette = self.palettes[indexPath.row]
                self.delegate?.didSelectColor(selectedPalette.color, hexCode: selectedPalette.hexCode)
            })
            .disposed(by: disposeBag)
        
        // 기본 팔레트 로드
        loadDefaultPalettes()
        loadCustomPalettes()
    }
    
    // MARK: - Public Methods
    
    func refreshPalettes() {
        loadCustomPalettes()
        colorCollectionView.reloadData()
    }
    
    
    private func updateButtonVisibility(showSelectButton: Bool) {
        // 애니메이션 없이 즉시 변경
        editButton.isHidden = showSelectButton
        selectButton.isHidden = !showSelectButton
        
    }
    
    // MARK: - Private Methods
    
    private func toggleEditMode(_ isEditing: Bool) {
        isEditMode = isEditing
        
        // 애니메이션 없이 버튼 상태 즉시 변경
        editButton.isHidden = isEditing
        doneButton.isHidden = !isEditing
        selectButton.isHidden = true
        
        // 선택 초기화
        selectedIndexPathRelay.accept(nil)
        
        // 모든 셀의 삭제 버튼 상태 업데이트
        updateAllCellsDeleteButtonState()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateAllCellsDeleteButtonState()
    }
    
    private func updateAllCellsDeleteButtonState() {
        // 현재 보이는 모든 셀에 대해 삭제 버튼 상태 업데이트
        for indexPath in colorCollectionView.indexPathsForVisibleItems {
            if let cell = colorCollectionView.cellForItem(at: indexPath) as? ColorPaletteCell {
                if indexPath.row < palettes.count {
                    let palette = palettes[indexPath.row]
                    cell.showDeleteButton(isEditMode && palette.isCustom)
                    cell.setInteractionEnabled(!isEditMode || palette.isCustom) // 편집 모드에서 커스텀 팔레트만 상호작용 가능
                } else {
                    // 추가 버튼은 편집 모드에서 비활성화
                    cell.showDeleteButton(false)
                    cell.setInteractionEnabled(!isEditMode)
                }
            }
        }
    }
    
    private func updateSelectedCell(indexPath: IndexPath?) {
        colorCollectionView.indexPathsForVisibleItems.forEach { visibleIndexPath in
            if let cell = colorCollectionView.cellForItem(at: visibleIndexPath) as? ColorPaletteCell {
                cell.isSelected = (visibleIndexPath == indexPath)
                
                // 편집 모드에서는 삭제 버튼 표시/숨김 처리
                if isEditMode && visibleIndexPath.row < palettes.count {
                    let palette = palettes[visibleIndexPath.row]
                    cell.showDeleteButton(palette.isCustom)
                } else {
                    cell.showDeleteButton(false)
                }
            }
        }
    }
    
    private func loadDefaultPalettes() {
        // 기본 색상 팔레트 설정
        let defaultPalettes: [ColorPalette] = [
            ColorPalette(id: "palette_1", name: "핑크", color: UIColor(hex: "FF9E9E"), hexCode: "FF9E9E", isCustom: false),
            ColorPalette(id: "palette_2", name: "연보라", color: UIColor(hex: "B39DDB"), hexCode: "B39DDB", isCustom: false),
            ColorPalette(id: "palette_3", name: "하늘", color: UIColor(hex: "81D4FA"), hexCode: "81D4FA", isCustom: false),
            ColorPalette(id: "palette_4", name: "민트", color: UIColor(hex: "80CBC4"), hexCode: "80CBC4", isCustom: false),
            ColorPalette(id: "palette_5", name: "연두", color: UIColor(hex: "C5E1A5"), hexCode: "C5E1A5", isCustom: false),
            ColorPalette(id: "palette_6", name: "노랑", color: UIColor(hex: "FFF59D"), hexCode: "FFF59D", isCustom: false),
            ColorPalette(id: "palette_7", name: "주황", color: UIColor(hex: "FFCC80"), hexCode: "FFCC80", isCustom: false),
            ColorPalette(id: "palette_8", name: "회색", color: UIColor(hex: "E0E0E0"), hexCode: "E0E0E0", isCustom: false),
            ColorPalette(id: "palette_9", name: "남색", color: UIColor(hex: "90CAF9"), hexCode: "90CAF9", isCustom: false),
            ColorPalette(id: "palette_10", name: "그레이블루", color: UIColor(hex: "B0BEC5"), hexCode: "B0BEC5", isCustom: false),
            ColorPalette(id: "palette_11", name: "레드", color: UIColor(hex: "EF9A9A"), hexCode: "EF9A9A", isCustom: false),
            ColorPalette(id: "palette_12", name: "퍼플", color: UIColor(hex: "CE93D8"), hexCode: "CE93D8", isCustom: false)
        ]
        
        palettes = defaultPalettes
    }
    
    private func loadCustomPalettes() {
        // UserDefaults에서 저장된 팔레트 로드
        if let savedPalettes = UserDefaults.standard.array(forKey: "customColorPalettes") as? [[String: Any]] {
            let customPalettes = savedPalettes.compactMap { ColorPalette.fromDictionary($0) }
            
            // 커스텀 팔레트만 추가 (기본 팔레트는 유지)
            palettes = palettes.filter { !$0.isCustom } + customPalettes
        }
    }
    
    // 새 팔레트 추가
    func addNewColorPalette(color: UIColor, hexCode: String) {
        let id = "custom_\(UUID().uuidString)"
        let newPalette = ColorPalette(
            id: id,
            name: "사용자 정의",
            color: color,
            hexCode: hexCode,
            isCustom: true
        )
        
        // 현재 팔레트에 추가
        palettes.append(newPalette)
        
        // UserDefaults에 저장
        var savedPalettes = UserDefaults.standard.array(forKey: "customColorPalettes") as? [[String: Any]] ?? []
        savedPalettes.append(newPalette.toDictionary())
        UserDefaults.standard.set(savedPalettes, forKey: "customColorPalettes")
        
        // 컬렉션뷰 업데이트
        colorCollectionView.reloadData()
    }
    
    func removeColorPalette(at indexPath: IndexPath) {
        guard indexPath.row < palettes.count else { return }
        
        let paletteToRemove = palettes[indexPath.row]
        
        // 기본 팔레트는 삭제 불가
        guard paletteToRemove.isCustom else { return }
        
        // 팔레트 배열에서 제거
        palettes.remove(at: indexPath.row)
        
        // UserDefaults에서도 제거
        if var savedPalettes = UserDefaults.standard.array(forKey: "customColorPalettes") as? [[String: Any]] {
            savedPalettes.removeAll { dict in
                guard let paletteId = dict["id"] as? String else { return false }
                return paletteId == paletteToRemove.id
            }
            UserDefaults.standard.set(savedPalettes, forKey: "customColorPalettes")
        }
        
        // 컬렉션뷰 업데이트 (애니메이션 없이 삭제)
        UIView.performWithoutAnimation {
            colorCollectionView.deleteItems(at: [indexPath])
        }
    }

    
    // 새 색상 선택 화면 표시
    private func showColorPicker() {
        guard let viewController = findViewController() else { return }
        
        let colorPickerVC = ColorPickerViewController()
        colorPickerVC.onColorSelected = { [weak self] color, hexCode in
            self?.addNewColorPalette(color: color, hexCode: hexCode)
        }
        
        viewController.present(colorPickerVC, animated: true)
    }
    
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }
        return nil
    }
}

// MARK: - UICollectionViewDataSource
extension ColorPaletteView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return palettes.count + 1 // 팔레트 + 추가 버튼
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorPaletteCell", for: indexPath) as! ColorPaletteCell
           
           if indexPath.row < palettes.count {
               // 색상 팔레트 셀
               let palette = palettes[indexPath.row]
               cell.configure(with: palette.color, name: palette.name, hexCode: palette.hexCode)
               cell.isAddButton = false
               
               // 편집 모드에서는 사용자 정의 색상에 삭제 버튼 표시
               cell.showDeleteButton(isEditMode && palette.isCustom)
               
               // 편집 모드에서는 커스텀 팔레트만 상호작용 가능
               cell.setInteractionEnabled(!isEditMode || palette.isCustom)
               
               // 삭제 버튼 액션 설정
               cell.deleteAction = { [weak self, weak cell] in
                   guard let self = self else { return }
                   
                   // 현재 인덱스패스 계산 (셀이 이동했을 수 있으므로)
                   if let currentIndexPath = self.colorCollectionView.indexPath(for: cell!) {
                       self.removeColorPalette(at: currentIndexPath)
                   }
               }
           } else {
               // 추가 버튼 셀
               cell.configureAsAddButton()
               cell.isAddButton = true
               cell.showDeleteButton(false)
               
               // 편집 모드에서는 추가 버튼 비활성화
               cell.setInteractionEnabled(!isEditMode)
           }
           
           return cell
       }
}

// MARK: - UICollectionViewDelegate
extension ColorPaletteView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 편집 모드에서는 선택 처리 안함
        if isEditMode {
               collectionView.deselectItem(at: indexPath, animated: false)
               return
           }
           
           print("Cell selected at: \(indexPath.row)")
           if indexPath.row == palettes.count {
               // 추가 버튼 선택 시 컬러 피커 표시
               showColorPicker()
               collectionView.deselectItem(at: indexPath, animated: true)
               selectedIndexPathRelay.accept(nil) // 선택 상태 초기화
           } else {
               // 이미 선택된 셀을 다시 선택한 경우 선택 해제
               if let selectedIndexPath = selectedIndexPathRelay.value, selectedIndexPath == indexPath {
                   selectedIndexPathRelay.accept(nil) // 선택 상태 초기화
                   collectionView.deselectItem(at: indexPath, animated: true)
                   // 애니메이션으로 선택 버튼 숨기고 편집 버튼 표시
                   updateButtonVisibility(showSelectButton: false)
               } else {
                   // 새로운 셀 선택 시 선택 상태 업데이트
                   selectedIndexPathRelay.accept(indexPath)
                   updateSelectedCell(indexPath: indexPath)
                   // 애니메이션으로 편집 버튼 숨기고 선택 버튼 표시
                   updateButtonVisibility(showSelectButton: true)
               }
           }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ColorPaletteView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 20) / 3 // 한 줄에 3개 셀
        return CGSize(width: width, height: width + 30) // 색상 + 텍스트 공간
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 터치가 컬렉션 뷰 내부에서 발생하면 제스처를 무시
        let location = touch.location(in: colorCollectionView)
        if colorCollectionView.bounds.contains(location) {
            return false
        }
        return true
    }
}
