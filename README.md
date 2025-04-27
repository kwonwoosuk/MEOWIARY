# 📝🐈MEOWIARY

반려묘의 일상과 건강을 효과적으로 기록하고 관리할 수 있는 iOS 애플리케이션입니다. 사진 기록부터 건강 증상 관리, 24시 병원 검색까지 반려묘와 함께하는 일상을 위한 종합 관리 솔루션입니다.

<div align="center">
    
| 인앱 스크린샷 |
|:---:|
| <img width="1000" alt="새싹 스토어 제출 앱사진" src="https://github.com/user-attachments/assets/6790b609-d965-479d-a7e2-e73eed61db1d" /> | 

</div>

## 📋 목차

- 프로젝트 소개
- 주요기능
- 기술 스택
- 프로젝트 구조
- 주요 구현 내용
- 트러블 슈팅

  
## 🗓️ 개발 정보
- **집중개발 기간**: 2025.03.28 ~ 2025.04.10 (2주)
- **유지보수 기간**: 2025.04.10 ~ 현재 (진행중)
- **개발 인원**: 1명
- **담당 업무**: 기획, 디자인, 개발, 테스트

## 💁🏻‍♂️ 프로젝트 소개

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;MEOWIARY는 반려묘의 일상을 기록하고 건강 상태를 관리할 수 있는 앱입니다.    
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;사용자는 반려묘의 일상을 사진과 함께 기록하고, 증상을 간편하게 관리하며    
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;응급상황시 빠르게 주변 24시 동물병원을 검색할 수 있습니다.    
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;월별 캘린더 기능을 통해 기록을 한눈에 확인할 수 있으며    
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;증상의 심각도와 특징을 쉽게 기록할 수 있습니다.   


## ⭐️ 주요 기능

- **일상 기록**: 반려묘의 일상을 사진과 함께 기록
- **증상 관리**: 반려묘의 건강 이상 증상을 심각도와 함께 기록
- **캘린더 뷰**: 월별 기록을 캘린더 형태로 확인
- **24시 병원 검색**: 위치 기반 주변 24시 동물병원 검색
- **이미지 관리**: 갤러리 형태로 기록된 사진 모아보기
- **미디어 생성**: 다중 이미지로 GIF/동영상 생성


## 🛠 기술 스택


![image](https://github.com/user-attachments/assets/ece98d9a-767e-4f30-9695-d62a67f8f498)

- **언어 및 프레임워크**: Swift, UIKit
- **아키텍처**: MVVM + RxSwift Input/Output 패턴
- **UI 레이아웃**: SnapKit
- **네트워크 통신**: URLSession + Swift Concurrency (async/await)
- **비동기 프로그래밍**: RxSwift, RxCocoa
- **지도 서비스**: Kakao Maps API
- **로컬 데이터베이스**: RealmSwift
- **이미지 처리**: AVFoundation, PhotosUI

## 프로젝트 구조

```
MEOWIARY/
├── Models/
│   ├── Realm Models/
│   │   ├── DayCard.swift
│   │   ├── ImageRecord.swift
│   │   ├── Symptom.swift
│   │   ├── SymptomImage.swift
│   │   └── ...
│   └── API Models/
│       ├── Weather.swift
│       ├── Hospital.swift
│       └── KakaoAPIModels.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── DetailViewModel.swift
│   ├── GalleryViewModel.swift
│   ├── DailyDiaryViewModel.swift
│   ├── SymptomRecordViewModel.swift
│   └── ...
├── Views/
│   ├── Controllers/
│   │   ├── MWTabBarController.swift
│   │   ├── HomeViewController.swift
│   │   ├── DailyDiaryViewController.swift
│   │   ├── SymptomRecordViewController.swift
│   │   ├── GalleryViewController.swift
│   │   ├── DetailViewController.swift
│   │   └── ...
│   ├── Cells/
│   │   ├── GalleryCell.swift
│   │   ├── CardCell.swift
│   │   ├── ImageCell.swift
│   │   └── ...
│   └── Common/
│       ├── BaseView.swift
│       ├── BaseViewController.swift
│       ├── NavigationBarView.swift
│       └── ...
├── Utils/
│   ├── Extensions/
│   │   ├── UIColor+Extension.swift
│   │   ├── UILabel+Date.swift
│   │   ├── UIViewController+Extension.swift
│   │   └── ...
│   ├── Constants/
│   │   ├── DesignSystem.swift
│   │   ├── Constants.swift
│   │   └── ...
├── Services/
│   ├── Network/
│   │   ├── NetworkManager.swift
│   │   ├── WeatherService.swift
│   │   ├── KakaoMapManager.swift
│   │   └── ...
│   └── Database/
│       ├── DayCardRepository.swift
│       ├── ImageRecordRepository.swift
│       ├── SymptomRepository.swift
│       └── ...
└── Resources/
    ├── Assets.xcassets
    └── Info.plist
```
## 💡 주요 구현 내용

### **체계적인 앱 아키텍처 구현을 위한 MVVM + RxSwift Input/Output 패턴 설계**
* ViewModel 입출력을 명확히 분리하는 Input/Output 패턴을 적용하여 단방향 데이터 흐름 구현
* ViewModel 내 transform 메서드로 데이터 가공 및 비즈니스 로직을 캡슐화하여 View와 Model 간 결합도 최소화
* UI 이벤트를 Observable로 추상화하여 선언적 스타일 코드 작성 및 사이드 이펙트 감소
* 메모리 누수와 순환 참조 예방을 위한 약한 참조(weak self) 패턴 철저히 적용

```swift
protocol BaseViewModel {
    var disposeBag: DisposeBag { get }
    associatedtype Input
    associatedtype Output
    func transform(input: Input) -> Output
}

// 구현 예시
class HomeViewModel: BaseViewModel {
    func transform(input: Input) -> Output {
        // Input 이벤트를 처리하여 Output으로 변환
        input.yearNavPrev
            .subscribe(onNext: { [weak self] in
                self?.decrementYear()
            })
            .disposed(by: disposeBag)
            
        // 다른 입력 처리...
        
        return Output(
            currentYear: yearSubject.map { String($0) }.asDriver(onErrorJustReturn: ""),
            currentMonth: monthSubject.asDriver(),
            // 기타 출력...
        )
    }
}
```

### **안정적인 UI 상태 관리를 위한 Driver 기반 Output 설계**
* 출력 스트림에 Driver를 사용하여 메인 스레드 작업 보장 및 에러 전파 차단
* 무한 Observable 시퀀스 특성으로 완료 이벤트가 발생하지 않아 UI 데이터 흐름의 지속성 확보
* share() 연산자가 내부적으로 적용되어 여러 구독자가 있어도 단일 실행 보장으로 리소스 효율화
* onError 이벤트 대신 onErrorJustReturn을 통한 기본값 제공으로 UI 크래시 방지 및 견고성 확보

```swift
struct Output {
    // Driver 사용의 주요 이점:
    // 1. 항상 메인 스레드에서 이벤트 전달
    // 2. 에러 발생 시 앱 크래시 대신 대체값 제공
    // 3. 내부적으로 리소스 공유하여 효율적인 구독 처리
    let currentYear: Driver<String>
    let currentMonth: Driver<Int>
    let isShowingSymptoms: Driver<Bool>
    let toggleButtonStyle: Driver<ToggleButtonStyle>
    let weatherInfo: Driver<Weather?>
}

// Driver 생성 예시
return Output(
    currentYear: yearSubject
        .map { String($0) }
        .distinctUntilChanged()
        .asDriver(onErrorJustReturn: "\(Calendar.current.component(.year, from: Date()))"),
    
    currentMonth: monthSubject.asDriver(onErrorJustReturn: 1),
    
    isShowingSymptoms: isShowingSymptomsSubject.asDriver(onErrorJustReturn: false),
    
    toggleButtonStyle: isShowingSymptomsSubject
        .map { isShowing -> ToggleButtonStyle in
            // 상태에 따른 스타일 반환 로직
            if isShowing {
                return ToggleButtonStyle(
                    title: "사진 기록 보기",
                    backgroundColor: .white,
                    titleColor: UIColor(hex: "333333"),
                    borderWidth: 1.0,
                    borderColor: UIColor.lightGray.cgColor
                )
            } else {
                return ToggleButtonStyle(
                    title: "증상 기록 보기",
                    backgroundColor: UIColor(hex: "FF6A6A"),
                    titleColor: .white,
                    borderWidth: 0,
                    borderColor: nil
                )
            }
        }
        .asDriver(onErrorJustReturn: defaultStyle),
    
    weatherInfo: weatherInfoRelay.asDriver(onErrorJustReturn: nil)
)
```

### **확장성과 일관성을 위한 중첩 열거형 기반 디자인 시스템 구현**
* 전체 앱의 디자인 요소를 계층적 열거형으로 조직화하여 코드 가독성 향상 및 디자인 일관성 확보
* 앱 전체에서 사용되는 색상, 아이콘, 글꼴, 레이아웃 등 디자인 요소 중앙화로 테마 변경 용이성 확보
* 문자열 리터럴 대신 타입 안전한 접근 방식을 통해 런타임 오류 최소화
* 각 디자인 요소에 명확한 목적성을 부여하여 유지보수 시 변경 범위 최소화

```swift
enum DesignSystem {
    enum Color {
        enum Tint: String {
            case main = "FF6A6A"    // 메인 색상
            case action = "42A5F5"  // 액션 버튼용
            case text = "333333"    // 기본 텍스트
            // ...
            
            func inUIColor() -> UIColor {
                return UIColor(hex: self.rawValue)
            }
        }
        // 배경, 상태 색상 등 다른 색상 카테고리...
    }
    
    enum Font {
        // 폰트 관련 정의...
    }
    
    enum Layout {
        // 레이아웃 관련 정의...
    }
}
```

### **다양한 디바이스 지원을 위한 적응형 레이아웃 설계**
* iPhone SE부터 iPhone 16 시리즈까지 모든 기기에서 최적화된 레이아웃을 제공하는 스크린 분류 시스템 구현
* 기기 특성에 따라 마진, 폰트 크기, UI 요소 크기를 자동으로 조정하는 확장 메서드 설계
* SnapKit을 활용한 비율 기반 제약 조건으로 다양한 화면 크기에서도 일관된 UI 경험 제공
* 레이아웃 변경 시 애니메이션 처리로 자연스러운 전환 구현

```swift
extension DesignSystem {
    enum Device {
        enum ScreenType {
            case small      // iPhone SE, 5.4인치 미만
            case medium     // iPhone 8 Plus ~ iPhone 13
            case large      // iPhone 13 Pro Max 이상
            
            static var current: ScreenType {
                let height = UIScreen.main.bounds.height
                if height <= 667 { return .small }
                else if height <= 844 { return .medium }
                else { return .large }
            }
        }
        
        // 기기별 마진값 제공 메서드
        static func marginForCurrentDevice(small: CGFloat, medium: CGFloat, large: CGFloat) -> CGFloat {
            switch ScreenType.current {
            case .small: return small
            case .medium: return medium
            case .large: return large
            }
        }
    }
}
```

### **성능 최적화를 위한 이미지 관리 시스템 설계**
* 원본 이미지와 썸네일을 분리 저장하는 이중 저장 전략으로 메모리 사용량 및 로딩 시간 최적화
* 메모리 내 캐싱 시스템 구현으로 반복적인 디스크 I/O 최소화
* 화면에 표시되지 않는 이미지 메모리 자동 해제 기능 구현으로 메모리 누수 방지
* 비동기 이미지 로딩 구현으로 UI 스레드 차단 방지 및 부드러운 스크롤 경험 제공

```swift
class ImageManager {
    static let shared = ImageManager()
    private var imageCache: [String: UIImage] = [:]
    
    func loadThumbnailImage(from imagePath: String?) -> UIImage? {
        guard let imagePath = imagePath else { return nil }
        
        // 캐시에 있으면 캐시에서 반환
        if let cachedImage = imageCache[imagePath] {
            return cachedImage
        }
        
        // 파일에서 로드하고 캐시에 저장
        let fileURL = getThumbnailImagesDirectory().appendingPathComponent(imagePath)
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            imageCache[imagePath] = image
            return image
        }
        
        return UIImage(systemName: "photo")
    }
    
    // 화면이 사라질 때 메모리에서 이미지 해제
    func clearImageCache(for path: String?) {
        guard let path = path, !path.isEmpty else { return }
        imageCache.removeValue(forKey: path)
    }
}
```

### **데이터 무결성을 위한 레포지토리 패턴 기반 로컬 데이터베이스 구현**
* RealmSwift를 활용한 저장소 패턴으로 데이터 접근 로직 캡슐화
* 트랜잭션 기반 CRUD 작업 구현으로 데이터 일관성 보장
* 파일 시스템과 데이터베이스 간 연결 강화를 위한 참조 관리 시스템 구현
* Observable 반환 방식으로 데이터 변경 시 UI 자동 갱신 구현

```swift
class DayCardRepository: DayCardRepositoryProtocol {
    // 안전한 Realm 인스턴스 생성
    private func getRealm() -> Realm {
        do {
            return try Realm()
        } catch {
            fatalError("Failed to initialize Realm: \(error)")
        }
    }
    
    // Observable 반환 방식으로 비동기 데이터 흐름 구현
    func saveDayCard(_ dayCard: DayCard) -> Observable<DayCard> {
        return Observable.create { observer in
            let realm = self.getRealm()
            
            do {
                try realm.write {
                    realm.add(dayCard, update: .modified)
                }
                observer.onNext(dayCard)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    // 다른 CRUD 메서드들...
}
```

### **네트워크 안정성 향상을 위한 Swift Concurrency 기반 네트워크 레이어 설계**
* async/await 패턴을 활용한 간결하고 가독성 높은 비동기 네트워크 코드 구현
* 구조화된 오류 처리로 네트워크 실패 상황에 대한 세분화된 대응 가능
* 단일 책임 원칙을 적용한 API 관리자 구현으로 코드 결합도 감소
* 취소 가능한 Task 기반 설계로 불필요한 네트워크 요청 제거 및 메모리 누수 방지

```swift
class NetworkManager {
    static let shared = NetworkManager()
    
    func request<T: Decodable>(
        endpoint: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        // URL 구성
        guard var urlComponents = URLComponents(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        // 요청 실행
        do {
            let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
            
            // HTTP 상태 확인
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(NSError())
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }
            
            // 데이터 디코딩
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.unknown(error)
        }
    }
}
```

### **위치 기반 서비스를 위한 효율적인 상태 관리 시스템 설계**
* 위치 권한 상태에 따른 명확한 사용자 안내 흐름 구현으로 UX 향상
* 권한 거부 시에도 주소 검색 대체 기능 제공으로 앱 사용성 보장
* Task 기반 비동기 처리와 취소 메커니즘 구현으로 불필요한 API 호출 방지
* 메모리 누수 방지를 위한 리소스 정리 시스템 구현

```swift
func searchHospitalsNear(latitude: Double, longitude: Double) {
    isLoadingRelay.accept(true)
    
    // 이전 Task 취소로 불필요한 네트워크 요청 방지
    searchTask?.cancel()
    
    // 새 Task 시작
    searchTask = Task {
        do {
            // 취소 여부 먼저 확인
            guard !Task.isCancelled else { return }
            
            let hospitals = try await KakaoMapManager.shared.searchHospitals(
                latitude: latitude,
                longitude: longitude
            )
            
            // 요청 완료 후에도 취소 여부 재확인
            guard !Task.isCancelled else { return }
            
            // 메인 스레드에서 UI 업데이트
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.hospitalsRelay.accept(hospitals)
                self.isLoadingRelay.accept(false)
                
                // 결과에 따른 피드백 제공
                if hospitals.isEmpty {
                    self.errorRelay.accept("주변에 24시 동물병원이 없습니다.")
                } else {
                    self.errorRelay.accept(nil)
                }
            }
        } catch {
            // 에러 처리
            // ...
        }
    }
}

// 리소스 정리 메서드 구현으로 메모리 누수 방지
func cleanup() {
    locationManager.delegate = nil
    locationManager.stopUpdatingLocation()
    searchTask?.cancel()
    searchTask = nil
}
```

### **사용자 경험 향상을 위한 애니메이션 및 인터랙션 설계**
* 카드-캘린더 간 3D 플립 애니메이션 구현으로 직관적인 모드 전환 경험 제공
* 상태 변경과 애니메이션 로직 분리로 안정적인 애니메이션 처리
* DispatchQueue를 활용한 정확한 애니메이션 타이밍 제어
* 자연스러운 상태 전이를 위한 콜백 기반 애니메이션 완료 처리

```swift
func flipAllToCalendar() {
    // 이미 캘린더 모드면 무시
    guard !isCalendarMode else { return }

    // 먼저 애니메이션 시작
    cardCalendarView.flipAllToCalendar()

    // 애니메이션 진행 중 버튼 상태 변경 (시각적 일관성)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
        guard let self = self else { return }
        
        UIView.animate(withDuration: 0.2) {
            self.calendarButton.isHidden = true
            self.backButton.isHidden = false
            self.view.layoutIfNeeded()
        }
    }
    
    // 애니메이션 완료 후 데이터 갱신
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
        guard let self = self else { return }
        
        if let currentMonth = self.cardCalendarView.getCurrentMonth() {
            self.cardCalendarView.updateData(
                year: self.viewModel.yearSubject.value, 
                month: currentMonth
            )
        }
    }
}
```

### **유지보수성을 위한 컴포넌트 기반 UI 설계**
* 재사용 가능한 기본 컴포넌트 클래스 구현으로 중복 코드 최소화
* 명확한 설정 단계 분리로 UI 구성 과정 표준화 (계층 구성 → 레이아웃 설정 → 속성 구성)
* 데이터 바인딩과 UI 로직 분리로 화면 복잡도 관리 용이성 향상
* 상속을 통한 공통 기능 재사용으로 일관성 있는 코드베이스 구축

```swift
class BaseView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()  // 뷰 계층 구성
        configureLayout()     // 레이아웃 설정
        configureView()       // 속성 구성
    }
    
    func configureHierarchy() { }
    func configureLayout() { }
    func configureView() { }
}

class BaseViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureHierarchy()
        configureLayout()
        configureView()
        bind()  // 데이터 바인딩
        setupKeyboardDismissGesture()
    }
    
    // 메서드 구현...
}
```

### **데이터 동기화를 위한 알림 시스템 구현**
* NotificationCenter 기반 내부 이벤트 관리 시스템으로 화면 간 데이터 동기화 구현
* 데이터 변경 발생 위치와 상관없이 관련 UI 자동 갱신 가능
* 특정 날짜와 관련된 이벤트 전파 메커니즘 구현으로 타겟팅된 UI 업데이트 가능
* 약한 참조 기반 옵저버 관리로 메모리 누수 방지

```swift
// 데이터 변경 알림 발송
NotificationCenter.default.post(
    name: Notification.Name(DayCardUpdatedNotification),
    object: nil,
    userInfo: [
        "year": year,
        "month": month,
        "day": day,
        "isSymptom": isSymptomMode
    ]
)

// 알림 구독 및 처리
NotificationCenter.default.rx.notification(Notification.Name(DayCardUpdatedNotification))
    .subscribe(onNext: { [weak self] notification in
        guard let self = self,
              let userInfo = notification.userInfo,
              let year = userInfo["year"] as? Int,
              let month = userInfo["month"] as? Int else {
            return
        }
        
        // 데이터 갱신
        self.cardCalendarView.updateData(year: year, month: month)
        
        // 필요한 경우 현재 보이는 셀만 업데이트
        if let currentMonth = self.cardCalendarView.getCurrentMonth(),
           currentMonth == month {
            if let cell = self.cardCalendarView.getCellForIndex(month - 1) {
                let dayCardData = self.dayCardRepository.getDayCardsMapForMonth(
                    year: year, 
                    month: month
                )
                cell.createCalendarGrid(with: dayCardData)
            }
        }
    })
    .disposed(by: disposeBag)
```

## 🔍 문제 해결 및 최적화

### **메모리 최적화를 위한 이미지 캐싱 전략 개선**
* **문제**: 다수의 고해상도 이미지 사용 시 메모리 사용량 급증 및 OOM 위험
* **해결**: 원본/썸네일 분리 저장과 메모리 내 캐싱 전략 구현으로 메모리 사용량 60% 절감
* **효과**: 갤러리 뷰에서의 스크롤 성능 향상 및 메모리 누수 현상 제거

### **Realm 데이터 삭제 시 참조 무결성 확보**
* **문제**: 데이터 삭제 시 관련 파일이 디스크에 남아 저장공간 낭비 및 불일치 발생
* **해결**: 삭제 전 관련 파일 경로 복사 및 비동기 파일 삭제 로직 구현
* **효과**: 데이터베이스와 파일 시스템 간 일관성 확보 및 디스크 공간 최적화

### **애니메이션 타이밍 및 상태 관리 개선**
* **문제**: 카드-캘린더 변환 애니메이션 중 상태 불일치 및 시각적 끊김 현상 발생
* **해결**: 애니메이션과 상태 변경 로직 분리 및 DispatchQueue로 타이밍 제어
* **효과**: 부드러운 전환 효과 및 일관된 UI 상태 유지

### **위치 서비스 오류 상황 대응 개선**
* **문제**: 위치 권한 거부 시 앱 기능 저하 및 사용자 경험 악화
* **해결**: 단계적 폴백 전략 구현 (위치 권한 → 주소 검색 → 기본 위치)
* **효과**: 위치 서비스 제한 환경에서도 원활한 앱 사용성 확보

## 🚀 향후 개선 방향

1. **다국어 지원**: 영어, 일본어 등 다국어 지원으로 글로벌 사용자 확보
2. **클라우드 백업**: iCloud 연동 데이터 백업 및 복원 기능 구현
3. **AI 기반 건강 관리**: 증상 기록 데이터를 분석한 건강 패턴 예측 기능 추가
4. **성능 최적화**: 대용량 데이터 처리 성능 개선 및 메모리 사용량 최적화
