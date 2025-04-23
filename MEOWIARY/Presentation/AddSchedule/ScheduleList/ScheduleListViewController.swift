//
//  ScheduleListViewController.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/22/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

class ScheduleListViewController: BaseViewController {
    
    // MARK: - Properties
    private let viewModel = ScheduleListViewModel()
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    private let navigationBarView = CustomNavigationBarView()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ScheduleCell.self, forCellReuseIdentifier: "ScheduleCell")
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    private let emptyView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.isHidden = true
        return view
    }()
    
    private let emptyImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "calendar.badge.exclamationmark")
        imageView.tintColor = DesignSystem.Color.Tint.darkGray.inUIColor()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "등록된 일정이 없습니다"
        label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
        label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.medium)
        label.textAlignment = .center
        return label
    }()
    
    private let addScheduleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = DesignSystem.Color.Tint.main.inUIColor()
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 화면이 나타날 때마다 데이터 다시 로드
        viewModel.loadSchedules()
    }
    
    // MARK: - UI Setup
    override func configureHierarchy() {
        view.addSubview(navigationBarView)
        view.addSubview(tableView)
        view.addSubview(emptyView)
        
        emptyView.addSubview(emptyImageView)
        emptyView.addSubview(emptyLabel)
        
        navigationBarView.addSubview(addScheduleButton)
    }
    
    override func configureLayout() {
        navigationBarView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationBarView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        emptyView.snp.makeConstraints { make in
            make.center.equalTo(tableView)
            make.width.equalTo(200)
            make.height.equalTo(150)
        }
        
        emptyImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(60)
        }
        
        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyImageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
        }
        
        addScheduleButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-DesignSystem.Layout.standardMargin)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
    }
    
    override func configureView() {
        view.backgroundColor = .white
        navigationBarView.configure(title: "일정", leftButtonType: .back)
        tableView.delegate = self
    }
    
    override func bind() {
        // 뒤로가기 버튼
        navigationBarView.leftButtonTapObservable
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        // 추가 버튼
        addScheduleButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showAddScheduleScreen()
            })
            .disposed(by: disposeBag)
        
        // 테이블뷰 바인딩
        viewModel.schedules
            .drive(tableView.rx.items(cellIdentifier: "ScheduleCell", cellType: ScheduleCell.self)) { row, schedule, cell in
                cell.configure(with: schedule)
            }
            .disposed(by: disposeBag)
        
        // 빈 상태 표시
        viewModel.isEmpty
            .map { !$0 } // 비어있지 않으면 숨김
            .drive(emptyView.rx.isHidden)
            .disposed(by: disposeBag)
        
        // 비어있으면 테이블뷰 숨김
        viewModel.isEmpty
            .drive(tableView.rx.isHidden)
            .disposed(by: disposeBag)
        
        // 초기 데이터 로드
        viewModel.loadSchedules()
    }
    
    // MARK: - Private Methods
    private func showAddScheduleScreen() {
        let scheduleAddVC = ScheduleAddViewController()
        scheduleAddVC.modalPresentationStyle = .fullScreen
        present(scheduleAddVC, animated: true)
    }
}

// MARK: - UITableViewDelegate
extension ScheduleListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 일정 상세 보기 또는 편집 기능을 추가할 수 있습니다
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // 삭제 액션
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { [weak self] (action, view, completion) in
            guard let self = self else {
                completion(false)
                return
            }
            
            guard let schedule = self.viewModel.schedule(at: indexPath.row) else {
                completion(false)
                return
            }
            
            // 확인 알림
            let alert = UIAlertController(
                title: "일정 삭제",
                message: "'\(schedule.title)' 일정을 삭제하시겠습니까?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in
                completion(false)
            })
            
            alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { _ in
                self.viewModel.deleteSchedule(at: indexPath.row)
                completion(true)
            })
            
            self.present(alert, animated: true)
        }
        
        deleteAction.backgroundColor = .systemRed
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - ScheduleCell
class ScheduleCell: UITableViewCell {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let colorIndicator: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.medium)
        label.textColor = DesignSystem.Color.Tint.text.inUIColor()
        label.numberOfLines = 1
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.small)
        label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
        return label
    }()
    
    private let typeLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.regular(size: DesignSystem.Font.Size.small)
        label.textColor = DesignSystem.Color.Tint.darkGray.inUIColor()
        label.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        return label
    }()
    
    private let dDayLabel: UILabel = {
        let label = UILabel()
        label.font = DesignSystem.Font.Weight.bold(size: DesignSystem.Font.Size.small)
        label.textColor = .white
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
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
    
    private func setupUI() {
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(colorIndicator)
        containerView.addSubview(titleLabel)
        containerView.addSubview(dateLabel)
        containerView.addSubview(typeLabel)
        containerView.addSubview(dDayLabel)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }
        
        colorIndicator.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(4)
            make.width.equalTo(4)
            make.height.equalTo(40)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalTo(colorIndicator.snp.trailing).offset(12)
            make.trailing.equalTo(dDayLabel.snp.leading).offset(-8)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        typeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(dateLabel)
            make.leading.equalTo(dateLabel.snp.trailing).offset(8)
            make.height.equalTo(20)
            make.width.greaterThanOrEqualTo(50)
        }
        
        dDayLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(24)
        }
    }
    
    func configure(with schedule: Schedule) {
        titleLabel.text = schedule.title
        
        // 날짜 포맷팅
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 MM월 dd일"
        dateLabel.text = dateFormatter.string(from: schedule.date)
        
        // 일정 타입
        typeLabel.text = "  \(schedule.type.rawValue)  "
        
        // D-day 계산 및 표시
        let dDay = schedule.calculateDDay()
        let dDayText = schedule.dDayText()
        dDayLabel.text = dDayText
        
        // D-day에 따른 색상 설정
        if dDay == 0 {
            dDayLabel.backgroundColor = UIColor.systemRed
        } else if dDay > 0 && dDay <= 3 {
            dDayLabel.backgroundColor = UIColor.systemOrange
        } else if dDay > 3 {
            dDayLabel.backgroundColor = DesignSystem.Color.Tint.main.inUIColor()
        } else {
            dDayLabel.backgroundColor = UIColor.gray
        }
        
        // 색상 인디케이터 설정
        colorIndicator.backgroundColor = UIColor(hex: schedule.color)
    }
}

