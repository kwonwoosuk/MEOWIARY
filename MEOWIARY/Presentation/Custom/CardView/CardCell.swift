//
//  CardCell.swift - UI 및 마진 수정
//  MEOWIARY
//

import UIKit
import RxSwift
import SnapKit

final class CardCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    // MARK: - Properties
    private var monthImages: [String] = [
        "jan_image", "feb_image", "mar_image", "apr_image",
        "may_image", "jun_image", "jul_image", "aug_image",
        "sep_image", "oct_image", "nov_image", "dec_image"
    ]
    
    enum CardDisplayMode {
        case colorCard // 색상 모드
        case featureImage // 이미지 모드
    }
    
    private var popupBackgroundView: UIView?
    private var colorPaletteBackgroundView: UIView?
    
    private var year: Int = Calendar.current.component(.year, from: Date())
    private var month: Int = 1
    var isFlipped = false
    var isShowingSymptoms = false
    let disposeBag = DisposeBag()
    
    let dateTapped = PublishSubject<(year: Int, month: Int, day: Int)>()
    private var symptomsData: [Int: Bool] = [:]  // Dictionary to track days with symptoms
    private var displayMode: CardDisplayMode = .colorCard
    var selectFeatureImageAction: ((Int, Int) -> Void)?
    private var hasCustomFeatureImage: Bool = false
    private static var imageCache: [String: UIImage] = [:]
    
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = DesignSystem.Color.Background.card.inUIColor()
        view.layer.cornerRadius = DesignSystem.Layout.largeCornerRadius
        view.clipsToBounds = true
        return view
    }()
    
    private let monthLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.extraLarge)
        label.textColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.regular)
        label.textAlignment = .center
        label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
        return label
    }()
    
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 0.3
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let pageInfoLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.small)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let optionsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(DesignSystem.Icon.Control.options.toUIImage(), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    // Calendar View (뒷면)
    private let calendarContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = DesignSystem.Layout.largeCornerRadius
        view.isHidden = true
        view.clipsToBounds = true
        return view
    }()
    
    private let calendarMonthLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.large)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()
    
    private let calendarView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let daysStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        return stackView
    }()
    
    private let calendarGridView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundImageView.image = nil
        
        // 증상 데이터 초기화
        symptomsData.removeAll()
        
        // 캘린더 그리드 초기화 (모든 이미지 포함 뷰 제거)
        for subview in calendarGridView.subviews {
            subview.removeFromSuperview()
        }
        
        // 캘린더 버튼들의 이미지뷰도 제거 - 새 메서드 호출
        cleanupCalendarButtonImages()
    }
    
    
    private func cleanupCalendarButtonImages() {
        // 캘린더 그리드의 모든 버튼을 찾아서 이미지뷰 제거
        for subview in calendarGridView.subviews {
            if let button = subview as? UIButton {
                for btnSubview in button.subviews {
                    if btnSubview is UIImageView {
                        btnSubview.removeFromSuperview()
                    }
                }
                // 텍스트 복원
                button.titleLabel?.isHidden = false
                button.setTitleColor(nil, for: .normal) // 기본 색상으로 복원
            }
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        // 컨텐츠 뷰 설정
        
        loadDisplayMode()
        contentView.clipsToBounds = false
        
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.2
        contentView.layer.shadowOffset = CGSize(width: 0, height: 3)
        contentView.layer.shadowRadius = 5
        
        // ✅ 수정: 카드 간 마진 조정을 위한 컨텐츠 뷰 내부 마진 설정
        let horizontalMargin: CGFloat = 20  // 좌우 마진
        
        // Card View (전면)
        contentView.addSubview(containerView)
        containerView.addSubview(backgroundImageView)
        containerView.addSubview(monthLabel)
        containerView.addSubview(pageInfoLabel)
        containerView.addSubview(optionsButton)
        
        // Calendar View (후면)
        contentView.addSubview(calendarContainerView)
        calendarContainerView.addSubview(calendarMonthLabel)
        calendarContainerView.addSubview(calendarView)
        calendarView.addSubview(daysStackView)
        calendarView.addSubview(calendarGridView)
        calendarContainerView.addSubview(messageLabel)
        
        optionsButton.addTarget(self, action: #selector(optionsButtonTapped), for: .touchUpInside)
        
        // ✅ 수정: 좌우 마진 추가
        containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(horizontalMargin)
            make.trailing.equalToSuperview().offset(-horizontalMargin)
        }
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        monthLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(50)
            make.width.greaterThanOrEqualTo(80) // 최소 너비 설정
        }
        
        pageInfoLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.centerX.equalToSuperview()
        }
        
        optionsButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.trailing.equalToSuperview().offset(-16)
            make.width.height.equalTo(24)
        }
        
        // ✅ 수정: 캘린더 뷰 좌우 마진 추가
        calendarContainerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(horizontalMargin)
            make.trailing.equalToSuperview().offset(-horizontalMargin)
        }
        
        let isSmallScreen = UIScreen.main.bounds.height <= 667 // iPhone SE, iPhone 8
        
        calendarMonthLabel.snp.makeConstraints { make in
            if isSmallScreen {
                make.top.equalToSuperview().offset(DesignSystem.Layout.smallMargin)
            } else {
                make.top.equalToSuperview().offset(DesignSystem.Layout.standardMargin)
            }
            make.centerX.equalToSuperview()
            make.height.equalTo(30)
            make.width.greaterThanOrEqualTo(60) // 최소 너비 설정
        }
        
        calendarView.snp.makeConstraints { make in
            if isSmallScreen {
                make.top.equalTo(calendarMonthLabel.snp.bottom).offset(DesignSystem.Layout.smallMargin/2)
            } else {
                make.top.equalTo(calendarMonthLabel.snp.bottom).offset(DesignSystem.Layout.standardMargin)
            }
            make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
            make.height.equalTo(isSmallScreen ? 250 : 300)
        }
        
        daysStackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(30)
        }
        
        calendarGridView.snp.makeConstraints { make in
            make.top.equalTo(daysStackView.snp.bottom).offset(DesignSystem.Layout.smallMargin/2)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        messageLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(DesignSystem.Layout.standardMargin)
        }
        
        // 초기 설정 - 캘린더 뷰는 숨김
        calendarContainerView.isHidden = true
        createCalendarUI()
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
    
    // MARK: - Configuration
    func configure(forMonth month: Int, year: Int = Calendar.current.component(.year, from: Date()), dayCardData: [Int: DayCard] = [:]) {
        // 셀 태그 설정 (검색용)
        self.tag = month
        self.month = month
        self.year = year
        preloadImages()
        // 확실히 레이아웃 갱신
        self.layoutIfNeeded()
        loadDisplayMode()
        updateCardAppearance()
        // 월 이름 설정 (1-based index)
        let monthNames = ["1월", "2월", "3월", "4월", "5월", "6월",
                          "7월", "8월", "9월", "10월", "11월", "12월"]
        
        // Month label 텍스트 설정 및 강제 갱신
        UIView.performWithoutAnimation {
            monthLabel.text = monthNames[month - 1]
            calendarMonthLabel.text = monthNames[month - 1]
            monthLabel.layoutIfNeeded()
            calendarMonthLabel.layoutIfNeeded()
        }
        
        // Set page info
        let totalDaysInMonth = daysInMonth(month: month, year: year)
        pageInfoLabel.text = "1 / \(totalDaysInMonth)"
        
        // 월별 고정 색상 설정
        setMonthColor(month: month)
        
        // 디버그 로그
        print("월 셀 구성 완료: \(year)년 \(month)월, 태그: \(self.tag), 상태: \(isFlipped ? "캘린더" : "카드")")
        
        // 배경 이미지 로드
        loadMonthBackgroundImage(month: month)
        
        // 캘린더 그리드 업데이트 (플립 상태인 경우만)
        createCalendarGrid(with: dayCardData)
        
        // 현재 모드에 맞는 메시지 설정
        updateSymptomView(isShowing: isShowingSymptoms)
    }
    
    // 별도로 모드 관련 파라미터를 포함한 configure 메서드 추가 (필요시 사용)
    func configure(with dayCardData: [Int: DayCard] = [:], isSymptomMode: Bool = false, month: Int, year: Int = Calendar.current.component(.year, from: Date())) {
        // 증상 모드 상태 설정
        self.isShowingSymptoms = isSymptomMode
        
        // 기존 configure 메서드 호출
        configure(forMonth: month, year: year, dayCardData: dayCardData)
    }
    
    
    @objc private func dayButtonTapped(_ sender: UIButton) {
        let day = sender.tag
        print("Day \(day) selected in \(month)월 \(year)년")
        
        // 날짜 선택 이벤트 방출
        dateTapped.onNext((year: year, month: month, day: day))
    }
    
    // MARK: - Calendar UI Creation
    private func createCalendarUI() {
        
        daysStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add day labels (일, 월, 화, 수, 목, 금, 토)
        let days = ["일", "월", "화", "수", "목", "금", "토"]
        for (index, day) in days.enumerated() {
            let label = UILabel()
            label.text = day
            label.textAlignment = .center
            label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.small)
            
            // 일요일과 토요일에 색상 적용
            switch index {
            case 0: // 일요일
                label.textColor = UIColor(hex: "F44336") // 붉은색
            case 6: // 토요일
                label.textColor = UIColor(hex: "42A5F5") // 푸른색
            default:
                label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
            }
            
            daysStackView.addArrangedSubview(label)
        }
    }
    
    // CardCell.swift 파일의 기존 코드에 다음 내용을 추가/수정합니다
    
    // 1. optionsButtonTapped 메서드 수정
    @objc private func optionsButtonTapped() {
        guard let viewController = findViewController() else { return }
        
          let optionPopupView = CardOptionPopupView(month: month)
          optionPopupView.delegate = self
          optionPopupView.frame = viewController.view.bounds
          
          // 현재 선택된 모드에 맞게 버튼 강조 표시
          let currentOption: CardOptionPopupView.OptionType
          switch displayMode {
          case .colorCard:
              currentOption = .colorCard
          case .featureImage:
              currentOption = .featureImage
          }
          optionPopupView.updateSelectedOption(currentOption)
          
          // 뷰 컨트롤러의 뷰에 추가
          viewController.view.addSubview(optionPopupView)
          
          // 애니메이션으로 표시
          optionPopupView.showWithAnimation()
    }
    
    // 3. ColorPaletteView 표시 메서드 추가
    private func showColorPaletteView() {
        guard let viewController = findViewController() else { return }
        
        // 팝업 배경
        let popupBackground = UIView(frame: viewController.view.bounds)
        popupBackground.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        // ColorPaletteView 생성
        let colorPaletteView = ColorPaletteView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        colorPaletteView.delegate = self
        colorPaletteView.layer.cornerRadius = 16
        colorPaletteView.clipsToBounds = true
        
        // 화면에 추가
        viewController.view.addSubview(popupBackground)
        popupBackground.addSubview(colorPaletteView)
        
        // 제약 조건 설정
        colorPaletteView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            colorPaletteView.centerXAnchor.constraint(equalTo: popupBackground.centerXAnchor),
            colorPaletteView.centerYAnchor.constraint(equalTo: popupBackground.centerYAnchor),
            colorPaletteView.widthAnchor.constraint(equalTo: popupBackground.widthAnchor, multiplier: 0.9),
            colorPaletteView.heightAnchor.constraint(equalToConstant: 480)
        ])
        
        // 애니메이션
        popupBackground.alpha = 0
        colorPaletteView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        
        UIView.animate(withDuration: 0.25) {
            popupBackground.alpha = 1
            colorPaletteView.transform = .identity
        }
        
        // 참조 저장
        self.colorPaletteBackgroundView = popupBackground
        
        // 배경 탭 닫기 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeColorPalette))
        tapGesture.delegate = colorPaletteView
        popupBackground.addGestureRecognizer(tapGesture)
    }
    
    // 4. 색상 팔레트 닫기 메서드 추가
    @objc private func closeColorPalette(_ gesture: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.2, animations: {
                self.colorPaletteBackgroundView?.alpha = 0
            }) { _ in
                self.colorPaletteBackgroundView?.removeFromSuperview()
                self.colorPaletteBackgroundView = nil
            }
    }
    
    // 5. 월별 색상 로드 기능 수정 - setMonthColor 메서드 업데이트
    private func setMonthColor(month: Int) {
        // UserDefaults에서 저장된 색상 로드 시도
        let colorKey = "card_color_\(year)_\(month)"
        
        if let savedColorHex = UserDefaults.standard.string(forKey: colorKey) {
            // 저장된 색상이 있으면 사용
            containerView.backgroundColor = UIColor(hex: savedColorHex)
        } else {
            // 없으면 기본 색상 사용
            let defaultColors = [
                UIColor(hex: "FF9E80"), // 1월 - 연한 주황
                UIColor(hex: "FF8A80"), // 2월 - 연한 빨강
                UIColor(hex: "EA80FC"), // 3월 - 연한 보라
                UIColor(hex: "8C9EFF"), // 4월 - 연한 파랑
                UIColor(hex: "80D8FF"), // 5월 - 연한 하늘
                UIColor(hex: "A7FFEB"), // 6월 - 연한 민트
                UIColor(hex: "B9F6CA"), // 7월 - 연한 초록
                UIColor(hex: "FFFF8D"), // 8월 - 연한 노랑
                UIColor(hex: "FFD180"), // 9월 - 연한 주황
                UIColor(hex: "FF8A80"), // 10월 - 연한 빨강
                UIColor(hex: "B388FF"), // 11월 - 연한 보라
                UIColor(hex: "82B1FF")  // 12월 - 연한 파랑
            ]
            
            if month >= 1 && month <= 12 {
                containerView.backgroundColor = defaultColors[month - 1]
            } else {
                containerView.backgroundColor = DesignSystem.Color.Background.card.inUIColor()
            }
        }
    }
    
    // 새로운 액션 메서드들 추가
    @objc private func colorCardButtonTapped() {
        setDisplayMode(.colorCard)
        closePopup()
    }
    
    @objc private func featureImageButtonTapped() {
        setDisplayMode(.featureImage)
        closePopup()
    }
    
    @objc private func selectImageButtonTapped() {
        closePopup()
        if let action = selectFeatureImageAction {
            action(year, month)
        }
    }
    
    @objc private func colorSettingButtonTapped() {
        closePopup()
        showColorPaletteView()
    }
    
    @objc private func closePopup() {
        guard let popupBackground = popupBackgroundView else { return }
        
        UIView.animate(withDuration: 0.2, animations: {
            popupBackground.alpha = 0
        }) { _ in
            popupBackground.removeFromSuperview()
            self.popupBackgroundView = nil
        }
    }
    
    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: popupBackgroundView)
        
        // 컨테이너 뷰 영역이 아닌 경우에만 닫기 (컨테이너 뷰 영역을 탭하면 무시)
        if let containerView = popupBackgroundView?.subviews.first,
           !containerView.frame.contains(location) {
            closePopup()
        }
    }
    
    func setDisplayMode(_ mode: CardDisplayMode) {
        // 이미지 모드로 변경하려는데 이미지가 없는 경우
        if mode == .featureImage && !hasImagesForCurrentMonth() && !hasCustomFeatureImage {
            // 이미지가 없으면 카드 모드로 강제 설정
            displayMode = .colorCard
            // 사용자에게 피드백 제공
            if let viewController = findViewController() {
                viewController.showToast(message: "\(month)월에 저장된 이미지가 없습니다.")
            }
        } else {
            // 정상적으로 요청된 모드로 설정
            displayMode = mode
        }
        
        saveDisplayMode()
        updateCardAppearance()
    }
    
    // 대표 이미지 설정
    func setFeatureImage(_ image: UIImage?) {
        if let image = image {
            backgroundImageView.image = image
            backgroundImageView.alpha = 1.0 // 완전 불투명으로 설정
            hasCustomFeatureImage = true
            saveCustomFeatureImage(image)
            setDisplayMode(.featureImage)
        }
    }
    
    
    private func updateCardAppearance() {
        switch displayMode {
        case .colorCard:
            // 기본 색상 모드
            backgroundImageView.image = nil
            backgroundImageView.alpha = 0.3
            setMonthColor(month: month)
            
        case .featureImage:
            // 이미지가 있는지 다시 확인
            if !hasImagesForCurrentMonth() && !hasCustomFeatureImage {
                // 이미지가 없으면 색상 모드로 강제 전환
                displayMode = .colorCard
                saveDisplayMode()
                
                // 색상 모드 적용
                backgroundImageView.image = nil
                backgroundImageView.alpha = 0.3
                setMonthColor(month: month)
                return
            }
            
            // 대표 이미지 모드
            if hasCustomFeatureImage {
                // 사용자가 설정한 대표 이미지 로드
                
                loadCustomFeatureImage()
                backgroundImageView.alpha = 1.0
            } else {
                // 랜덤 이미지 로드
                loadRandomMonthImage()
                backgroundImageView.alpha = 1.0
            }
        }
    }
    
    private func hasImagesForCurrentMonth() -> Bool {
        let dayCardRepository = DayCardRepository()
        let dayCards = dayCardRepository.getDayCards(year: year, month: month)
        
        // 모든 DayCard에서 이미지 레코드 확인
        let hasImages = dayCards.contains { dayCard in
            return !dayCard.imageRecords.isEmpty
        }
        
        return hasImages
    }
    
    private func loadRandomMonthImage() -> Bool {
        // 플레이스홀더 색상 즉시 설정
        containerView.backgroundColor = DesignSystem.Color.Background.card.inUIColor()
        
        let dayCardRepository = DayCardRepository()
        let dayCards = dayCardRepository.getDayCards(year: year, month: month)
        
        var allImageRecords: [ImageRecord] = []
        for dayCard in dayCards {
            allImageRecords.append(contentsOf: dayCard.imageRecords)
        }
        
        if let randomImage = allImageRecords.randomElement(),
           let imagePath = randomImage.originalImagePath,
           let image = ImageManager.shared.loadOriginalImage(from: imagePath) {
            backgroundImageView.image = image
            backgroundImageView.alpha = 0.7
            containerView.backgroundColor = UIColor.clear
            return true
        } else {
            // 이미지가 없는 경우 색상 모드로 전환하는 로직 추가
            if displayMode == .featureImage {
                displayMode = .colorCard
                saveDisplayMode()
                backgroundImageView.image = nil
                backgroundImageView.alpha = 0.3
                setMonthColor(month: month)
            }
            return false
        }
    }
    
    // 사용자 정의 대표 이미지 저장 키
    private func featureImageKey() -> String {
        return "feature_image_\(year)_\(month)"
    }
    
    // 사용자 정의 대표 이미지 저장
    private func saveCustomFeatureImage(_ image: UIImage) {
        // 이미지를 디스크에 저장
        guard let data = image.jpegData(compressionQuality: 0.7) else { return }
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent(featureImageKey())
        
        do {
            try data.write(to: filePath)
            UserDefaults.standard.set(true, forKey: "has_" + featureImageKey())
        } catch {
            print("이미지 저장 실패: \(error)")
        }
    }
    
    // 사용자 정의 대표 이미지 로드
    private func loadCustomFeatureImage() -> Bool {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = documentsPath.appendingPathComponent(featureImageKey())
        
        if fileManager.fileExists(atPath: filePath.path),
           let data = try? Data(contentsOf: filePath),
           let image = UIImage(data: data) {
            backgroundImageView.image = image
            backgroundImageView.alpha = 1.0
            containerView.backgroundColor = UIColor.clear
            return true
        } else {
            // 커스텀 이미지가 없으면 hasCustomFeatureImage 플래그 업데이트
            hasCustomFeatureImage = false
            UserDefaults.standard.removeObject(forKey: "has_" + featureImageKey())
            
            // 랜덤 이미지 시도
            return loadRandomMonthImage()
        }
    }
    
    // 디스플레이 모드 저장
    private func saveDisplayMode() {
        let key = "display_mode_\(year)_\(month)"
        UserDefaults.standard.set(displayMode == .featureImage, forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    // 디스플레이 모드 로드
    private func loadDisplayMode() {
        let key = "display_mode_\(year)_\(month)"
        let customKey = "has_" + featureImageKey()
        
        hasCustomFeatureImage = UserDefaults.standard.bool(forKey: customKey)
        
        if UserDefaults.standard.bool(forKey: key) {
            displayMode = .featureImage
        } else {
            displayMode = .colorCard
        }
        
        print("CardCell: \(month)월 카드 디스플레이 모드 로드: \(displayMode == .featureImage ? "이미지" : "색상")")
    }
    
    func createCalendarGrid(with dayCardData: [Int: DayCard] = [:]) {
        
        let calendar = Calendar.current
        
        // Get first day of month and number of days
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        guard let firstDayOfMonth = calendar.date(from: components) else { return }
        
        // 첫 번째 요일 (1: 일요일, 2: 월요일, ..., 7: 토요일)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let numberOfDaysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)?.count ?? 30
        
        let isSmallScreen = UIScreen.main.bounds.height <= 667 // iPhone SE, iPhone 8
        
        // 그리드 생성을 위한 크기 계산
        let gridWidth = calendarGridView.bounds.width
        let buttonWidth = gridWidth / 7.0
        let buttonHeight = isSmallScreen ? buttonWidth * 0.9 : buttonWidth
        
        // 첫 번째 요일 조정 (0-based: 0 = 일요일, ..., 6 = 토요일)
        let firstWeekdayIndex = firstWeekday - 1
        
        // 각 날짜별 버튼 생성
        for day in 1...numberOfDaysInMonth {
            // 요일 계산 (0: 일요일, 1: 월요일, ..., 6: 토요일)
            let components = DateComponents(year: year, month: month, day: day)
            guard let date = calendar.date(from: components) else { continue }
            let weekday = calendar.component(.weekday, from: date) - 1 // 0-based for array indexing
            
            // 주차 계산 (0: 첫째 주, 1: 둘째 주, ...)
            let weekOfMonth = (day + firstWeekdayIndex - 1) / 7
            
            // 버튼 생성
            let dayButton = createDayButton(day: day, weekday: weekday)
            
            // 버튼 위치 계산
            let xPosition = CGFloat(weekday) * buttonWidth
            let yPosition = CGFloat(weekOfMonth) * buttonHeight
            
            // 버튼 크기 설정
            dayButton.frame = CGRect(
                x: xPosition,
                y: yPosition,
                width: buttonWidth,
                height: buttonHeight
            )
            
            // 그리드에 추가
            calendarGridView.addSubview(dayButton)
            
            // 오늘 날짜에 검정 바 추가
            if day == Calendar.current.component(.day, from: Date()) &&
                month == Calendar.current.component(.month, from: Date()) &&
                year == Calendar.current.component(.year, from: Date()) {
                addTodayIndicator(to: dayButton)
            }
            
            // 해당 날짜에 일정이 있는지 확인하고 표시
            var dateComponents = DateComponents()
            dateComponents.year = year
            dateComponents.month = month
            dateComponents.day = day
            
            if let targetDate = calendar.date(from: dateComponents),
               ScheduleManager.shared.hasSchedule(on: targetDate) {
                addScheduleIndicator(to: dayButton)
            }
            
            if let dayCard = dayCardData[day] {
                if isShowingSymptoms {
                    // 증상 모드일 때: 증상 심각도에 따른 색상 표시
                    if !dayCard.symptoms.isEmpty {
                        let maxSeverity = dayCard.symptoms.max { $0.severity < $1.severity }?.severity ?? 1
                        addSymptomIndicator(to: dayButton, severity: maxSeverity)
                    }
                } else {
                    // 사진 모드일 때: 이미지 표시
                    if !dayCard.imageRecords.isEmpty,
                       let imageRecord = dayCard.imageRecords.first,
                       let thumbnailPath = imageRecord.thumbnailImagePath {
                        addImageIndicator(to: dayButton, imagePath: thumbnailPath)
                    }
                }
            }
        }
    }
    
    private func preloadImages() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            // 커스텀 이미지 미리 로드
            if self.hasCustomFeatureImage {
                let fileManager = FileManager.default
                let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let filePath = documentsPath.appendingPathComponent(self.featureImageKey())
                
                if fileManager.fileExists(atPath: filePath.path),
                   let data = try? Data(contentsOf: filePath),
                   let image = UIImage(data: data) {
                    let cacheKey = "\(self.year)_\(self.month)_custom"
                    CardCell.imageCache[cacheKey] = image
                }
            }
            
            // 랜덤 이미지 후보들 미리 로드
            let dayCardRepository = DayCardRepository()
            let dayCards = dayCardRepository.getDayCards(year: self.year, month: self.month)
            
            // 이미지 레코드 중 앞에서 최대 5개만 미리 로드 (성능 고려)
            let imageRecords = dayCards.flatMap { $0.imageRecords }.prefix(5)
            
            for record in imageRecords {
                if let path = record.originalImagePath {
                    _ = self.getImageWithCaching(path: path)
                }
            }
        }
    }
    
    private func getImageWithCaching(path: String) -> UIImage? {
        // 캐시에 있으면 캐시에서 반환
        let cacheKey = "\(year)_\(month)_\(path)"
        if let cachedImage = CardCell.imageCache[cacheKey] {
            return cachedImage
        }
        
        // 캐시에 없으면 로드하고 캐싱
        if let image = ImageManager.shared.loadOriginalImage(from: path) {
            CardCell.imageCache[cacheKey] = image
            return image
        }
        
        return nil
    }
    
    private func resetButtonDisplay(_ button: UIButton) {
        // 언더바 뷰 찾기
        var todayIndicator: UIView?
        for subview in button.subviews {
            // 언더바 뷰의 특성으로 식별
            if subview != button.titleLabel && subview.frame.height == 2 &&
               subview.backgroundColor == DesignSystem.Color.Tint.text.inUIColor() {
                todayIndicator = subview
                break
            }
        }
        
        // 언더바를 제외한 기존 서브뷰 제거
        for subview in button.subviews {
            if subview is UIImageView || (subview != button.titleLabel && subview != todayIndicator) {
                subview.removeFromSuperview()
            }
        }
        
        // 버튼 태그를 이용해 날짜 가져오기
        let day = button.tag
        
        // 날짜를 기반으로 요일 계산
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        if let date = Calendar.current.date(from: components) {
            let weekday = Calendar.current.component(.weekday, from: date) - 1 // 0이 일요일
            
            // 요일에 맞는 색상 다시 설정
            if weekday == 0 {  // 일요일
                button.setTitleColor(UIColor(hex: "F44336"), for: .normal) // 빨간색
            } else if weekday == 6 {  // 토요일
                button.setTitleColor(UIColor(hex: "42A5F7"), for: .normal) // 파란색
            } else {
                button.setTitleColor(DesignSystem.Color.Tint.darkGray.inUIColor(), for: .normal)
            }
        } else {
            // 날짜 변환 실패 시 기본 색상으로
            button.setTitleColor(DesignSystem.Color.Tint.darkGray.inUIColor(), for: .normal)
        }
        
        // 텍스트 보이게 설정
        button.titleLabel?.isHidden = false
        
        // 언더바가 있으면 최상위로 가져오기
        if let indicator = todayIndicator {
            button.bringSubviewToFront(indicator)
        }
    }
    
    // MARK: - Add Indicator    
    private func addScheduleIndicator(to button: UIButton) {
        // 일정 표시 원형 테두리 추가
        let indicatorView = UIView()
        indicatorView.backgroundColor = .clear
        indicatorView.layer.borderWidth = 1.5  // 더 얇게 설정
        indicatorView.layer.borderColor = DesignSystem.Color.Tint.main.inUIColor().cgColor
        
        
        let padding: CGFloat = 7.0
        let width = button.bounds.width - padding * 2
        let height = button.bounds.height - padding * 2
        
        indicatorView.layer.cornerRadius = width / 2
        
        // 터치 이벤트 방지
        indicatorView.isUserInteractionEnabled = false
        
        button.addSubview(indicatorView)
        indicatorView.frame = CGRect(
            x: padding,
            y: padding,
            width: width,
            height: height
        )
        
        // 버튼 뒤에 위치하도록 설정 (텍스트 가리지 않게)
        button.sendSubviewToBack(indicatorView)
    }
    
    
    private func addSymptomIndicator(to button: UIButton, severity: Int) {
        let isSmallScreen = UIScreen.main.bounds.height <= 667
        let indicatorSize: CGFloat = isSmallScreen ? 20 : 24
        
        // 버튼에서 언더바 뷰 찾기 (이미 addTodayIndicator에서 추가된 경우)
        var todayIndicator: UIView?
        for subview in button.subviews {
            // 언더바 뷰의 특성으로 식별 (높이가 2인 검은색 막대)
            if subview != button.titleLabel && subview.frame.height == 2 &&
               subview.backgroundColor == DesignSystem.Color.Tint.text.inUIColor() {
                todayIndicator = subview
                break
            }
        }
        
        // 기존 이미지뷰나 다른 표시기들 제거하되 언더바는 유지
        for subview in button.subviews {
            if subview != button.titleLabel && subview != todayIndicator {
                subview.removeFromSuperview()
            }
        }
        
        // 증상 심각도에 따른 색상 지정
        var indicatorColor: UIColor
        switch severity {
        case 1:
            indicatorColor = DesignSystem.Color.Status.negative1.inUIColor()
        case 2:
            indicatorColor = DesignSystem.Color.Status.negative2.inUIColor()
        case 3:
            indicatorColor = DesignSystem.Color.Status.negative3.inUIColor()
        case 4:
            indicatorColor = DesignSystem.Color.Status.negative4.inUIColor()
        case 5:
            indicatorColor = DesignSystem.Color.Status.negative5.inUIColor()
        default:
            indicatorColor = DesignSystem.Color.Status.negative1.inUIColor()
        }
        
        // 원형 표시기 생성
        let indicator = UIView()
        indicator.backgroundColor = indicatorColor
        indicator.layer.cornerRadius = indicatorSize / 2
        
        // 터치 이벤트 비활성화
        indicator.isUserInteractionEnabled = false
        
        button.addSubview(indicator)
        indicator.frame = CGRect(
            x: (button.frame.width - indicatorSize) / 2,
            y: (button.frame.height - indicatorSize) / 2,
            width: indicatorSize,
            height: indicatorSize
        )
        
        // 텍스트만 숨기고 언더바는 유지
        button.titleLabel?.isHidden = true
        button.setTitleColor(.clear, for: .normal)
        
        // 언더바가 가려지지 않도록 최상위로 가져오기
        if let indicator = todayIndicator {
            button.bringSubviewToFront(indicator)
        }
    }
    
    // 이미지 표시 메서드 수정
    private func addImageIndicator(to button: UIButton, imagePath: String?) {
        guard let imagePath = imagePath else {
            // 이미지 없음 - 텍스트 표시 복원
            resetButtonDisplay(button)
            return
        }
        
        let isSmallScreen = UIScreen.main.bounds.height <= 667
        let indicatorSize: CGFloat = isSmallScreen ? 18 : 22
        
        // 버튼에서 언더바 뷰 찾기 (이미 addTodayIndicator에서 추가된 경우)
        var todayIndicator: UIView?
        for subview in button.subviews {
            // 언더바 뷰의 특성으로 식별 (높이가 2인 검은색 막대)
            if subview != button.titleLabel && subview.frame.height == 2 &&
               subview.backgroundColor == DesignSystem.Color.Tint.text.inUIColor() {
                todayIndicator = subview
                break
            }
        }
        
        // 기존 이미지뷰를 제거하되 언더바는 유지
        for subview in button.subviews {
            if subview is UIImageView || (subview != button.titleLabel && subview != todayIndicator) {
                subview.removeFromSuperview()
            }
        }
        
        // 실제 이미지가 존재하는지 먼저 확인
        if let thumbnail = ImageManager.shared.loadThumbnailImage(from: imagePath) {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = indicatorSize / 2
            imageView.image = thumbnail
            
            // 터치 이벤트 비활성화
            imageView.isUserInteractionEnabled = false
            
            button.addSubview(imageView)
            imageView.frame = CGRect(
                x: (button.frame.width - indicatorSize) / 2,
                y: (button.frame.height - indicatorSize) / 2,
                width: indicatorSize,
                height: indicatorSize
            )
            
            // 이미지가 있을 때 날짜 텍스트만 숨기고 언더바는 그대로 유지
            button.titleLabel?.isHidden = true
            button.setTitleColor(.clear, for: .normal)
            
            // 언더바가 가려지지 않도록 최상위로 가져오기
            if let indicator = todayIndicator {
                button.bringSubviewToFront(indicator)
            }
        } else {
            // 이미지가 로드되지 않으면 텍스트 표시 복원
            button.titleLabel?.isHidden = false
            button.setTitleColor(nil, for: .normal)
        }
    }
    
    private func createDayButton(day: Int, weekday: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(String(day), for: .normal)
        
        let isSmallScreen = UIScreen.main.bounds.height <= 667
        button.titleLabel?.font = DesignSystem.Font.Weight.regular(
            size: isSmallScreen ? DesignSystem.Font.Size.small : DesignSystem.Font.Size.medium
        )
        
        // 일요일(0)이면 빨간색, 토요일(6)이면 파란색
        if weekday == 0 {
            button.setTitleColor(UIColor(hex: "F44336"), for: .normal) // 붉은색
        } else if weekday == 6 {
            button.setTitleColor(UIColor(hex: "42A5F5"), for: .normal) // 푸른색
        } else {
            button.setTitleColor(DesignSystem.Color.Tint.darkGray.inUIColor(), for: .normal)
        }
        
        button.tag = day
        button.addTarget(self, action: #selector(dayButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private func addTodayIndicator(to button: UIButton) {
        let indicatorHeight: CGFloat = 2
        let indicatorWidth: CGFloat = button.frame.width * 0.6
        
        let indicator = UIView()
        indicator.backgroundColor = DesignSystem.Color.Tint.text.inUIColor() // 검정색
        
        button.addSubview(indicator)
        
        indicator.frame = CGRect(
            x: (button.frame.width - indicatorWidth) / 2,
            y: button.frame.height - indicatorHeight - 2, // 하단에서 약간 위
            width: indicatorWidth,
            height: indicatorHeight
        )
    }
    
    func checkAndUpdateDisplayMode() {
        if displayMode == .featureImage {
            // 이미지 존재 여부 확인
            if !hasImagesForCurrentMonth() && !hasCustomFeatureImage {
                // 이미지가 없으면 카드 모드로 강제 전환
                displayMode = .colorCard
                saveDisplayMode()
                updateCardAppearance()
            }
        }
    }
    
    // MARK: - Flipping Methods
    func flipToCalendar(animated: Bool = true) {
        // 이미 뒤집힌 상태면 종료
        if isFlipped {
            return
        }
        
        saveDisplayMode()
        
        if animated {
            // 애니메이션 옵션 수정 - 일정한 속도로 뒤집기
            UIView.transition(
                with: self.contentView,
                duration: 0.4,
                options: [.transitionFlipFromLeft, .allowUserInteraction, .curveLinear], // .curveLinear 추가
                animations: {
                    self.containerView.isHidden = true
                    self.calendarContainerView.isHidden = false
                },
                completion: { _ in
                    self.isFlipped = true
                    print("CardCell: \(self.month)월 카드 뒤집기 애니메이션 완료")
                }
            )
        } else {
            // 애니메이션 없이 즉시 상태 변경
            containerView.isHidden = true
            calendarContainerView.isHidden = false
            isFlipped = true
        }
        
        // 디버그 로그
        if animated {
            print("CardCell: \(month)월 카드를 캘린더로 플립 시작 (태그: \(self.tag))")
        }
    }
    
    // 뒤로 플립 애니메이션 개선
    func flipToCard(animated: Bool = true) {
            // 이미 카드 상태면 무시
            if !isFlipped {
                return
            }
            
            // 애니메이션 전 모드 로드
            loadDisplayMode()
            
            // 애니메이션 시작 전에 이미지 미리 로드
            if displayMode == .featureImage {
                var preloadedImage: UIImage? = nil
                
                // 이미지 미리 로드 (애니메이션 시작 전에)
                if hasCustomFeatureImage {
                    let fileManager = FileManager.default
                    let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let filePath = documentsPath.appendingPathComponent(featureImageKey())
                    
                    if fileManager.fileExists(atPath: filePath.path),
                       let data = try? Data(contentsOf: filePath),
                       let image = UIImage(data: data) {
                        preloadedImage = image
                        backgroundImageView.image = image
                        backgroundImageView.alpha = 1.0
                        containerView.backgroundColor = UIColor.clear
                    }
                } else if hasImagesForCurrentMonth() {
                    // 랜덤 이미지 미리 로드
                    let dayCardRepository = DayCardRepository()
                    let dayCards = dayCardRepository.getDayCards(year: year, month: month)
                    
                    var allImageRecords: [ImageRecord] = []
                    for dayCard in dayCards {
                        allImageRecords.append(contentsOf: dayCard.imageRecords)
                    }
                    
                    if let randomImage = allImageRecords.randomElement(),
                       let imagePath = randomImage.originalImagePath,
                       let image = ImageManager.shared.loadOriginalImage(from: imagePath) {
                        preloadedImage = image
                        backgroundImageView.image = image
                        backgroundImageView.alpha = 1.0
                        containerView.backgroundColor = UIColor.clear
                    }
                }
                
                // 이미지 로드 실패 시 색상 모드로 폴백
                if preloadedImage == nil {
                    displayMode = .colorCard
                    saveDisplayMode()
                    backgroundImageView.image = nil
                    backgroundImageView.alpha = 0.0
                    setMonthColor(month: month)
                }
            } else {
                // 색상 모드는 간단하게 즉시 적용
                backgroundImageView.image = nil
                backgroundImageView.alpha = 0.0
                setMonthColor(month: month)
            }
            
            if animated {
                UIView.transition(
                    with: self.contentView,
                    duration: 0.4,
                    options: [.transitionFlipFromRight, .allowUserInteraction, .curveLinear],
                    animations: {
                        self.calendarContainerView.isHidden = true
                        self.containerView.isHidden = false
                    },
                    completion: { _ in
                        self.isFlipped = false
                        print("CardCell: \(self.month)월 카드 되돌리기 애니메이션 완료")
                    }
                )
            } else {
                // 애니메이션 없을 때는 바로 완료 처리
                calendarContainerView.isHidden = true
                containerView.isHidden = false
                isFlipped = false
            }
            
            // 디버그 로그
            if animated {
                print("CardCell: \(self.month)월 카드를 원래대로 되돌리기 시작 (태그: \(self.tag))")
            }
        }
    
    // MARK: - Helper Methods
    private func daysInMonth(month: Int, year: Int) -> Int {
        let calendar = Calendar.current
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        
        if let date = calendar.date(from: dateComponents),
           let range = calendar.range(of: .day, in: .month, for: date) {
            return range.count
        }
        
        return 30 // Default fallback
    }
    
    private func loadMonthBackgroundImage(month: Int) {
        // 실제 앱에서는 월별 이미지를 로드
        // 현재는 플레이스홀더 사용
        backgroundImageView.image = UIImage(named: "placeholder_image")
    }
    
    // MARK: - Public Methods
    func updateSymptomView(isShowing: Bool) {
        // 애니메이션 없이 텍스트 즉시 변경
        UIView.performWithoutAnimation {
            if isShowing {
                messageLabel.text = "날짜를 선택하여 증상 기록을 확인하세요."
            } else {
                messageLabel.text = "날짜를 선택해 일기를 작성해보세요."
            }
            messageLabel.setNeedsDisplay()
            messageLabel.layoutIfNeeded()
        }
        
        // 중요: 모드 변경 저장
        self.isShowingSymptoms = isShowing
        
        // 캘린더 모드인 경우 그리드 다시 그리기
        if isFlipped {
            // 클린업 및 재생성을 위해 prepareForReuse 호출
            prepareForReuse()
            // 타이틀과 같은 기본 정보 보존
            if let label = self.monthLabel.text {
                self.monthLabel.text = label
            }
            if let label = self.calendarMonthLabel.text {
                self.calendarMonthLabel.text = label
            }
        }
    }
    
    func getMessageLabel() -> UILabel {
        return messageLabel
    }
    
//    private func updateCalendarWithSymptoms() {
//        // Sample data - this would come from your ViewModel
//        symptomsData = [5: true, 18: true, 24: true]
//        createCalendarGrid()
//    }
    
//    private func resetCalendarSymptoms() {
//        // Clear symptom data
//        symptomsData.removeAll()
//        createCalendarGrid()
//    }
}


extension CardCell: ColorPaletteViewDelegate {
    func didSelectColor(_ color: UIColor, hexCode: String) {
        // 선택한 색상으로 카드 배경색 변경
        containerView.backgroundColor = color
        
        // UserDefaults에 선택한 색상 저장
        UserDefaults.standard.set(hexCode, forKey: "card_color_\(year)_\(month)")
        
        // 컬러 팔레트 팝업 닫기
        if let background = colorPaletteBackgroundView {
            UIView.animate(withDuration: 0.2, animations: {
                background.alpha = 0
            }) { _ in
                background.removeFromSuperview()
                self.colorPaletteBackgroundView = nil
            }
        }
        
        // 색상 카드 모드로 설정
        setDisplayMode(.colorCard)
    }
    
    func didCancelSelection() {
        // 컬러 팔레트 팝업 닫기
        if let background = colorPaletteBackgroundView {
            UIView.animate(withDuration: 0.2, animations: {
                background.alpha = 0
            }) { _ in
                background.removeFromSuperview()
                self.colorPaletteBackgroundView = nil
            }
        }
    }
}

extension CardCell: CardOptionPopupDelegate {
    func didSelectOption(_ option: CardOptionPopupView.OptionType) {
            switch option {
            case .colorCard:
                setDisplayMode(.colorCard)
                updateCardAppearance() // 즉시 UI 갱신
            case .colorSetting:
                showColorPaletteView()
            case .featureImage:
                setDisplayMode(.featureImage)
                updateCardAppearance() // 즉시 UI 갱신
            case .selectFeatureImage:
                if let action = selectFeatureImageAction {
                    action(year, month)
                }
            }
        }
    
    func didCancelOptionSelection() {
        
    }
}
