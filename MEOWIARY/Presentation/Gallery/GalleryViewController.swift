//
//  GalleryViewController.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/3/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class GalleryViewController: BaseViewController {
  
  // MARK: - Properties
  private let viewModel = GalleryViewModel()
  private let disposeBag = DisposeBag()
  private let yearMonthSubject = PublishSubject<(Int, Int)>()
  
  private var selectedYear: Int = Calendar.current.component(.year, from: Date())
  private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
  
  private let years: [Int] = Array(2000...2100)
  private let months: [String] = ["1월", "2월", "3월", "4월", "5월", "6월", "7월", "8월", "9월", "10월", "11월", "12월"]
  
  // MARK: - UI Components
  private let navigationView: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    return view
  }()
  

  
  private let yearMonthButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("2025년 4월", for: .normal)
    button.titleLabel?.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.large)
    button.setTitleColor(DesignSystem.Color.Tint.text.inUIColor(), for: .normal)
    button.contentHorizontalAlignment = .center
    return button
  }()
  

  
  private let menuButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "line.3.horizontal.decrease"), for: .normal)
    button.tintColor = DesignSystem.Color.Tint.text.inUIColor()
    return button
  }()
  
  private lazy var collectionView: UICollectionView = {
    let collectionView = UICollectionView(
      frame: .zero,
      collectionViewLayout: createCollectionViewLayout()
    )
    collectionView.backgroundColor = .white
    collectionView.showsVerticalScrollIndicator = false
    collectionView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    return collectionView
  }()
  
  private let emptyView: UIView = {
    let view = UIView()
    view.isHidden = true
    return view
  }()
  
  private let emptyImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(systemName: "photo")
    imageView.tintColor = DesignSystem.Color.Tint.darkGray.inUIColor()
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()
  
  private let emptyLabel: UILabel = {
    let label = UILabel()
    label.text = "선택한 월에 저장된 사진이 없습니다"
    label.textAlignment = .center
    label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
    label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
    return label
  }()
  
  private let datePickerOverlay: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    view.isHidden = true
    return view
  }()
  
  private let datePickerContainer: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    view.layer.cornerRadius = 16
    return view
  }()
  
  private let datePicker: UIPickerView = {
    let picker = UIPickerView()
    return picker
  }()
  
  private let datePickerConfirmButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("선택", for: .normal)
    button.backgroundColor = DesignSystem.Color.Tint.main.inUIColor()
    button.setTitleColor(.white, for: .normal)
    button.layer.cornerRadius = 8
    button.titleLabel?.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.medium)
    return button
  }()
  
  private let datePickerCancelButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("취소", for: .normal)
    button.backgroundColor = DesignSystem.Color.Tint.lightGray.inUIColor()
    button.setTitleColor(DesignSystem.Color.Tint.darkGray.inUIColor(), for: .normal)
    button.layer.cornerRadius = 8
    button.titleLabel?.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
    return button
  }()
  
  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    updateYearMonthTitle()
    datePicker.delegate = self
    datePicker.dataSource = self
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel.refreshData(year: selectedYear, month: selectedMonth)
  }
  
  // MARK: - UI Setup
  override func configureHierarchy() {
    view.addSubview(navigationView)
    //    navigationView.addSubview(backButton)
    navigationView.addSubview(yearMonthButton)
    //    navigationView.addSubview(addButton)
//    navigationView.addSubview(menuButton) // 추후 정렬버튼으로 업데이트 예정
    
    view.addSubview(collectionView)
    view.addSubview(emptyView)
    emptyView.addSubview(emptyImageView)
    emptyView.addSubview(emptyLabel)
    
    view.addSubview(datePickerOverlay)
    datePickerOverlay.addSubview(datePickerContainer)
    datePickerContainer.addSubview(datePicker)
    datePickerContainer.addSubview(datePickerConfirmButton)
    datePickerContainer.addSubview(datePickerCancelButton)
  }
  
  override func configureLayout() {
    navigationView.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(50)
    }
  
    yearMonthButton.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.height.equalTo(30)
    }
    
//    menuButton.snp.makeConstraints { make in //  정렬버튼으로 업데이트 예정
//      make.trailing.equalToSuperview().offset(-16)
//      make.centerY.equalToSuperview()
//      make.width.height.equalTo(24)
//    }
    
    collectionView.snp.makeConstraints { make in
      make.top.equalTo(navigationView.snp.bottom)
      make.leading.trailing.bottom.equalToSuperview()
    }
    
    emptyView.snp.makeConstraints { make in
      make.center.equalTo(collectionView)
      make.width.equalTo(240)
      make.height.equalTo(150)
    }
    
    emptyImageView.snp.makeConstraints { make in
      make.top.equalToSuperview()
      make.centerX.equalToSuperview()
      make.width.height.equalTo(60)
    }
    
    emptyLabel.snp.makeConstraints { make in
      make.top.equalTo(emptyImageView.snp.bottom).offset(20)
      make.leading.trailing.equalToSuperview()
      make.centerX.equalToSuperview()
    }
    
    datePickerOverlay.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    
    datePickerContainer.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.width.equalToSuperview().multipliedBy(0.85)
      make.height.equalTo(350)
    }
    
    datePicker.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(20)
      make.leading.trailing.equalToSuperview().inset(20)
      make.height.equalTo(200)
    }
    
    datePickerCancelButton.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(20)
      make.bottom.equalToSuperview().offset(-20)
      make.height.equalTo(50)
      make.width.equalTo((datePickerContainer.snp.width)).multipliedBy(0.42)
    }
    
    datePickerConfirmButton.snp.makeConstraints { make in
      make.trailing.equalToSuperview().offset(-20)
      make.bottom.equalToSuperview().offset(-20)
      make.height.equalTo(50)
      make.width.equalTo((datePickerContainer.snp.width)).multipliedBy(0.42)
    }
  }
  
  override func configureView() {
    view.backgroundColor = .white
    collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: "GalleryCell")
  }
  
  // MARK: - Binding
  override func bind() {
    //    backButton.rx.tap
    //      .subscribe(onNext: { [weak self] in
    //        self?.navigationController?.popViewController(animated: true)
    //      })
    //      .disposed(by: disposeBag)
    
    yearMonthButton.rx.tap
      .subscribe(onNext: { [weak self] in
        self?.showDatePicker()
      })
      .disposed(by: disposeBag)
    
    datePickerConfirmButton.rx.tap
      .subscribe(onNext: { [weak self] in
        guard let self = self else { return }
        let yearIndex = self.datePicker.selectedRow(inComponent: 0)
        let monthIndex = self.datePicker.selectedRow(inComponent: 1)
        let year = self.years[yearIndex]
        let month = monthIndex + 1
        self.selectedYear = year
        self.selectedMonth = month
        self.updateYearMonthTitle()
        self.yearMonthSubject.onNext((year, month))
        self.viewModel.refreshData(year: year, month: month)
        self.hideDatePicker()
      })
      .disposed(by: disposeBag)
    
    datePickerCancelButton.rx.tap
      .subscribe(onNext: { [weak self] in
        self?.hideDatePicker()
      })
      .disposed(by: disposeBag)
    
    let tapGesture = UITapGestureRecognizer()
    datePickerOverlay.addGestureRecognizer(tapGesture)
    
    tapGesture.rx.event
      .subscribe(onNext: { [weak self] recognizer in
        if recognizer.location(in: self?.datePickerOverlay).y < (self?.datePickerContainer.frame.minY ?? 0) ||
            recognizer.location(in: self?.datePickerOverlay).y > (self?.datePickerContainer.frame.maxY ?? 0) {
          self?.hideDatePicker()
        }
      })
      .disposed(by: disposeBag)
    
    let input = GalleryViewModel.Input(
      viewDidLoad: Observable.just(()),
      yearMonthSelected: yearMonthSubject.asObservable(),
      toggleFavoriteFilter: Observable.just(false)
    )
    
    let output = viewModel.transform(input: input)
    
    output.images
      .drive(collectionView.rx.items(cellIdentifier: "GalleryCell", cellType: GalleryCell.self)) { [weak self] (index, imageData, cell) in
        guard let self = self else { return }
        cell.configure(with: imageData, imageManager: self.viewModel.imageManager)
        
        cell.favoriteButtonTap
          .subscribe(onNext: { [weak self] in
            self?.viewModel.toggleFavorite(imageId: imageData.id)
          })
          .disposed(by: cell.disposeBag)
        
        cell.shareButtonTap
          .subscribe(onNext: { [weak self] in
            self?.shareImage(imageData: imageData)
          })
          .disposed(by: cell.disposeBag)
      }
      .disposed(by: disposeBag)
    
    output.isEmpty
      .drive(onNext: { [weak self] isEmpty in
        self?.emptyView.isHidden = !isEmpty
      })
      .disposed(by: disposeBag)
    
    collectionView.rx.modelSelected(GalleryViewModel.ImageData.self)
      .subscribe(onNext: { [weak self] imageData in
        guard let self = self else { return }
        self.showImageDetail(year: imageData.year, month: imageData.month, day: imageData.day)
      })
      .disposed(by: disposeBag)
  }
  
  private func createCollectionViewLayout() -> UICollectionViewLayout {
    let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
      let itemSize = NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1.0),
        heightDimension: .absolute(140)
      )
      let item = NSCollectionLayoutItem(layoutSize: itemSize)
      item.contentInsets = NSDirectionalEdgeInsets(
        top: 6, leading: 16, bottom: 6, trailing: 16
      )
      let groupSize = NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1.0),
        heightDimension: .absolute(140)
      )
      let group = NSCollectionLayoutGroup.horizontal(
        layoutSize: groupSize,
        subitems: [item]
      )
      let section = NSCollectionLayoutSection(group: group)
      return section
    }
    return layout
  }
  
  private func updateYearMonthTitle() {
    yearMonthButton.setTitle("\(selectedYear)년 \(selectedMonth)월", for: .normal)
  }
  
  private func showDatePicker() {
    if let yearIndex = years.firstIndex(of: selectedYear) {
      datePicker.selectRow(yearIndex, inComponent: 0, animated: false)
    }
    if selectedMonth > 0 && selectedMonth <= 12 {
      datePicker.selectRow(selectedMonth - 1, inComponent: 1, animated: false)
    }
    
    datePickerOverlay.isHidden = false
    datePickerOverlay.alpha = 0
    UIView.animate(withDuration: 0.3) {
      self.datePickerOverlay.alpha = 1
    }
  }
  
  private func hideDatePicker() {
    UIView.animate(withDuration: 0.3, animations: {
      self.datePickerOverlay.alpha = 0
    }) { _ in
      self.datePickerOverlay.isHidden = true
    }
  }
  
  private func shareImage(imageData: GalleryViewModel.ImageData) {
    guard let image = viewModel.imageManager.loadOriginalImage(from: imageData.originalPath) else { return }
    let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
    if let popoverController = activityViewController.popoverPresentationController {
      popoverController.sourceView = self.view
      popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
      popoverController.permittedArrowDirections = []
    }
    present(activityViewController, animated: true)
  }
  
  private func showImageDetail(year: Int, month: Int, day: Int) {
    let detailVC = DetailViewController(
      year: year,
      month: month,
      day: day,
      imageManager: viewModel.imageManager
    )
    
    detailVC.onDelete = { [weak self] in
      guard let self = self else { return }
      self.viewModel.refreshData(year: self.selectedYear, month: self.selectedMonth)
    }
    
    detailVC.modalPresentationStyle = .fullScreen
    present(detailVC, animated: true)
  }
}

extension GalleryViewController: UIPickerViewDelegate, UIPickerViewDataSource {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 2
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    if component == 0 {
      return years.count
    } else {
      return months.count
    }
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    if component == 0 {
      return "\(years[row])년"
    } else {
      return months[row]
    }
  }
  
  func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
    return component == 0 ? 120 : 80
  }
}
