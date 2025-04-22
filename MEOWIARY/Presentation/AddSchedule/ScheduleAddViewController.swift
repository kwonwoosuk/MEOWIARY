//
//  ScheduleAddViewController.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/22/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import WidgetKit

class ScheduleAddViewController: BaseViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let viewModel = ScheduleAddViewModel()
    
    // MARK: - UI Components
    private let navigationBarView = CustomNavigationBarView()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()
    
    private let contentView = UIView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.medium)
        label.textColor = DesignSystem.Color.Tint.text.inUIColor()
        label.text = "일정 제목"
        return label
    }()
    
    private let titleTextField: UITextField = {
        let textField = UITextField()
        textField.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
        textField.placeholder = "일정 제목을 입력하세요"
        textField.borderStyle = .roundedRect
        textField.backgroundColor = DesignSystem.Color.Tint.lightGray.inUIColor()
        return textField
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.medium)
        label.textColor = DesignSystem.Color.Tint.text.inUIColor()
        label.text = "날짜 선택"
        return label
    }()
    
    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "ko_KR")
        picker.minimumDate = Date()
        return picker
    }()
    
    private let typeLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.medium)
        label.textColor = DesignSystem.Color.Tint.text.inUIColor()
        label.text = "일정 유형"
        return label
    }()
    
    private let typeSegmentedControl: UISegmentedControl = {
        let types = ["병원", "예방접종", "약", "검진", "기타"]
        let control = UISegmentedControl(items: types)
        control.selectedSegmentIndex = 0
        control.backgroundColor = DesignSystem.Color.Tint.lightGray.inUIColor()
        control.selectedSegmentTintColor = DesignSystem.Color.Tint.main.inUIColor()
        control.setTitleTextAttributes(
            [.foregroundColor: DesignSystem.Color.Tint.darkGray.inUIColor()],
            for: .normal
        )
        control.setTitleTextAttributes(
            [.foregroundColor: UIColor.white],
            for: .selected
        )
        return control
    }()
    
    private let colorLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.medium)
        label.textColor = DesignSystem.Color.Tint.text.inUIColor()
        label.text = "색상 선택"
        return label
    }()
    
    private lazy var colorCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 40, height: 40)
        layout.minimumLineSpacing = 10
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(ColorCell.self, forCellWithReuseIdentifier: "ColorCell")
        return collectionView
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("저장하기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.medium)
        button.backgroundColor = DesignSystem.Color.Tint.main.inUIColor()
        button.layer.cornerRadius = DesignSystem.Layout.cornerRadius
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - UI Setup
    override func configureHierarchy() {
        view.addSubview(navigationBarView)
        view.addSubview(scrollView)
        view.addSubview(saveButton)
        
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(titleTextField)
        contentView.addSubview(dateLabel)
        contentView.addSubview(datePicker)
        contentView.addSubview(typeLabel)
        contentView.addSubview(typeSegmentedControl)
        contentView.addSubview(colorLabel)
        contentView.addSubview(colorCollectionView)
    }
    
    override func configureLayout() {
        navigationBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        
        saveButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-DesignSystem.Layout.standardMargin)
            make.height.equalTo(50)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(navigationBarView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(saveButton.snp.top).offset(-DesignSystem.Layout.smallMargin)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
            make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
        }
        
        titleTextField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(DesignSystem.Layout.smallMargin)
            make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
            make.height.equalTo(50)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(titleTextField.snp.bottom).offset(DesignSystem.Layout.standardMargin)
            make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
        }
        
        datePicker.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(DesignSystem.Layout.smallMargin)
            make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
            make.height.equalTo(150)
        }
        
        typeLabel.snp.makeConstraints { make in
            make.top.equalTo(datePicker.snp.bottom).offset(DesignSystem.Layout.standardMargin)
            make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
        }
        
        typeSegmentedControl.snp.makeConstraints { make in
            make.top.equalTo(typeLabel.snp.bottom).offset(DesignSystem.Layout.smallMargin)
            make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
            make.height.equalTo(40)
        }
        
        colorLabel.snp.makeConstraints { make in
            make.top.equalTo(typeSegmentedControl.snp.bottom).offset(DesignSystem.Layout.standardMargin)
            make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
        }
        
        colorCollectionView.snp.makeConstraints { make in
            make.top.equalTo(colorLabel.snp.bottom).offset(DesignSystem.Layout.smallMargin)
            make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
            make.height.equalTo(60)
            make.bottom.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
        }
    }
    
    override func configureView() {
        view.backgroundColor = .white
        navigationBarView.configure(title: "일정 추가", leftButtonType: .close)
        
        colorCollectionView.delegate = self
        colorCollectionView.dataSource = self
    }
    
    override func bind() {
        navigationBarView.leftButtonTapObservable
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        // 저장 버튼 액션
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.saveSchedule()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    private func saveSchedule() {
        guard let title = titleTextField.text, !title.isEmpty else {
            showToast(message: "일정 제목을 입력해주세요")
            return
        }
        
        let selectedDate = datePicker.date
        let typeIndex = typeSegmentedControl.selectedSegmentIndex
        let scheduleTypes: [Schedule.ScheduleType] = [
            .hospital, .vaccination, .medicine, .checkup, .other
        ]
        
        let selectedColor = viewModel.colors[viewModel.selectedColorIndex.value]
        
        let schedule = Schedule(
            title: title,
            date: selectedDate,
            type: scheduleTypes[typeIndex],
            color: selectedColor
        )
        
        // 일정 저장
        ScheduleManager.shared.addSchedule(schedule)
        
        // UserDefaults 강제 동기화
        UserDefaults.standard.synchronize()
        
        // 위젯 업데이트 요청
        WidgetCenter.shared.reloadAllTimelines()
        
        // 저장 완료 토스트 메시지
        showToast(message: "일정이 추가되었습니다")
        
        // 화면 닫기
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.dismiss(animated: true)
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension ScheduleAddViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCell", for: indexPath) as? ColorCell else {
            return UICollectionViewCell()
        }
        
        let color = viewModel.colors[indexPath.item]
        let isSelected = viewModel.selectedColorIndex.value == indexPath.item
        
        cell.configure(with: color, isSelected: isSelected)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectedColorIndex.accept(indexPath.item)
        collectionView.reloadData()
    }
}

// MARK: - ColorCell
class ColorCell: UICollectionViewCell {
    private let colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 15
        view.clipsToBounds = true
        return view
    }()
    
    private let selectedIndicator: UIView = {
        let view = UIView()
        view.layer.borderWidth = 2
        view.layer.borderColor = DesignSystem.Color.Tint.text.inUIColor().cgColor
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(selectedIndicator)
        contentView.addSubview(colorView)
        
        selectedIndicator.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        colorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(30)
        }
    }
    
    func configure(with color: String, isSelected: Bool) {
        colorView.backgroundColor = UIColor(hex: color)
        selectedIndicator.isHidden = !isSelected
    }
}
