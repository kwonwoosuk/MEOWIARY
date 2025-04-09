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
    private let favoriteFilterEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let years: [Int] = Array(2000...2100)
    private let months: [String] = ["1월", "2월", "3월", "4월", "5월", "6월", "7월", "8월", "9월", "10월", "11월", "12월"]
    private let searchTextSubject = BehaviorRelay<String>(value: "")
    
    private var collectionViewTopConstraint: Constraint?
    
    // MARK: - UI Components
    private let navigationView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let favoriteFilterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.tintColor = DesignSystem.Color.Tint.darkGray.inUIColor()
        return button
    }()
    
    private let yearMonthButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("2025년 4월", for: .normal)
        button.titleLabel?.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.large)
        button.setTitleColor(DesignSystem.Color.Tint.text.inUIColor(), for: .normal)
        button.contentHorizontalAlignment = .center
        return button
    }()
    
    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        button.tintColor = DesignSystem.Color.Tint.text.inUIColor()
        return button
    }()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "날짜 또는 일기 내용 검색"
        searchBar.isHidden = true
        return searchBar
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
        navigationView.addSubview(favoriteFilterButton)
        navigationView.addSubview(yearMonthButton)
        navigationView.addSubview(searchButton)
        navigationView.addSubview(searchBar)
        
        view.addSubview(collectionView)
        view.addSubview(emptyView)
        emptyView.addSubview(emptyImageView)
        emptyView.addSubview(emptyLabel)
        
        view.addSubview(datePickerOverlay)
        datePickerOverlay.addSubview(datePickerContainer)
        datePickerContainer.addSubview(datePicker)
        datePickerContainer.addSubview(datePickerConfirmButton)
        datePickerContainer.addSubview(datePickerCancelButton)
        view.bringSubviewToFront(searchBar)
    }
    
    override func configureLayout() {
        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        
        favoriteFilterButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        
        yearMonthButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(30)
        }
        
        searchButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        
        collectionView.snp.makeConstraints { make in
            self.collectionViewTopConstraint = make.top.equalTo(navigationView.snp.bottom).constraint
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
        favoriteFilterButton.setImage(UIImage(systemName: "heart"), for: .normal)
        favoriteFilterButton.tintColor = DesignSystem.Color.Tint.main.inUIColor()
    }
    
    // MARK: - Binding
    override func bind() {
        favoriteFilterEnabledRelay
            .subscribe(onNext: { [weak self] isEnabled in
                let imageName = isEnabled ? "heart.fill" : "heart"
                let tintColor = isEnabled ?
                    DesignSystem.Color.Tint.main.inUIColor() :
                    DesignSystem.Color.Tint.darkGray.inUIColor()
                self?.favoriteFilterButton.setImage(UIImage(systemName: imageName), for: .normal)
                self?.favoriteFilterButton.tintColor = tintColor
            })
            .disposed(by: disposeBag)
        
        favoriteFilterButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                let newState = !self.favoriteFilterEnabledRelay.value
                self.favoriteFilterEnabledRelay.accept(newState)
                let message = newState ? "즐겨찾기한 항목만 표시합니다" : "모든 항목을 표시합니다"
                self.showToast(message: message)
            })
            .disposed(by: disposeBag)
        
        yearMonthButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showDatePicker()
            })
            .disposed(by: disposeBag)
        
        searchButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.searchBar.isHidden.toggle()
                if self.searchBar.isHidden {
                    self.searchTextSubject.accept("")
                    self.searchBar.resignFirstResponder()
                    self.collectionViewTopConstraint?.update(offset: 0)
                } else {
                    self.searchBar.becomeFirstResponder()
                    self.collectionViewTopConstraint?.update(offset: 50)
                }
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
        
        searchBar.rx.text.orEmpty
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind(to: searchTextSubject)
            .disposed(by: disposeBag)
        
        let searchBarTap = UITapGestureRecognizer()
        searchBar.addGestureRecognizer(searchBarTap)
        searchBarTap.rx.event
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, !self.searchBar.isHidden else { return }
                print("SearchBar tapped - Attempting to become first responder")
                self.searchBar.becomeFirstResponder()
            })
            .disposed(by: disposeBag)
        
        // 배경 탭 제스처 설정
        let backgroundTap = UITapGestureRecognizer()
        backgroundTap.delegate = self
        view.addGestureRecognizer(backgroundTap)
        backgroundTap.cancelsTouchesInView = false
        backgroundTap.rx.event
            .subscribe(onNext: { [weak self] recognizer in
                guard let self = self, !self.searchBar.isHidden, self.datePickerOverlay.isHidden else { return }
                let location = recognizer.location(in: self.view)
                let searchBarFrame = self.searchBar.frame
                print("Background tapped at: \(location), SearchBar frame: \(searchBarFrame)")
                if !searchBarFrame.contains(location) {
                    print("Hiding search bar via background tap")
                    self.searchBar.isHidden = true
                    self.searchTextSubject.accept("")
                    self.searchBar.resignFirstResponder()
                    self.collectionViewTopConstraint?.update(offset: 0)
                    UIView.animate(withDuration: 0.3) {
                        self.view.layoutIfNeeded()
                    }
                }
            })
            .disposed(by: disposeBag)
        
        let datePickerTap = UITapGestureRecognizer()
        datePickerOverlay.addGestureRecognizer(datePickerTap)
        datePickerTap.rx.event
            .subscribe(onNext: { [weak self] recognizer in
                guard let self = self else { return }
                let location = recognizer.location(in: self.datePickerOverlay)
                if location.y < self.datePickerContainer.frame.minY || location.y > self.datePickerContainer.frame.maxY {
                    self.hideDatePicker()
                }
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
        
        let input = GalleryViewModel.Input(
            viewDidLoad: Observable.just(()),
            yearMonthSelected: yearMonthSubject.asObservable(),
            toggleFavoriteFilter: favoriteFilterEnabledRelay.asObservable(),
            searchText: searchTextSubject.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.images
            .drive(collectionView.rx.items(cellIdentifier: "GalleryCell", cellType: GalleryCell.self)) { [weak self] (index, imageData, cell) in
                guard let self = self else { return }
                cell.configure(with: imageData, imageManager: self.viewModel.imageManager)
                
                let searchText = self.searchTextSubject.value
                let isMatch = !searchText.isEmpty && (
                    "\(imageData.day)".contains(searchText) ||
                    (imageData.notes?.lowercased().contains(searchText.lowercased()) ?? false)
                )
                cell.contentView.layer.borderWidth = isMatch ? 2 : 0
                cell.contentView.layer.borderColor = isMatch ? DesignSystem.Color.Tint.main.inUIColor().cgColor : nil
                
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
                if !self.searchBar.isHidden {
                    self.searchBar.isHidden = true
                    self.searchTextSubject.accept("")
                    self.searchBar.resignFirstResponder()
                    self.collectionViewTopConstraint?.update(offset: 0)
                    UIView.animate(withDuration: 0.3) {
                        self.view.layoutIfNeeded()
                    }
                }
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

// MARK: - UIPickerViewDelegate, UIPickerViewDataSource
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

// MARK: - UIGestureRecognizerDelegate
extension GalleryViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 터치가 컬렉션뷰의 셀에서 발생했는지 확인
        let location = touch.location(in: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: location),
           collectionView.cellForItem(at: indexPath) != nil {
            print("Touch in collection view cell at indexPath: \(indexPath)")
            return false // 셀 터치 시 제스처 무시
        }
        return true // 그 외의 경우 제스처 실행
    }
}
