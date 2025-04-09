//
//  ColorPickerViewController.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/10/25.
//

import UIKit
import SnapKit


class ColorPickerViewController: UIViewController {
    
    // MARK: - Properties
    var onColorSelected: ((UIColor, String) -> Void)?
    private var selectedColor: UIColor = .systemRed
    private var selectedHexCode: String = "FF0000"
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "색상 선택"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let colorPreview: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let hexLabel: UILabel = {
        let label = UILabel()
        label.text = "#FF0000"
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        return label
    }()
    
    private let redSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 255
        slider.value = 255
        slider.tintColor = .red
        return slider
    }()
    
    private let greenSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 255
        slider.value = 0
        slider.tintColor = .green
        return slider
    }()
    
    private let blueSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 255
        slider.value = 0
        slider.tintColor = .blue
        return slider
    }()
    
    private let redLabel: UILabel = {
        let label = UILabel()
        label.text = "R: 255"
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let greenLabel: UILabel = {
        let label = UILabel()
        label.text = "G: 0"
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let blueLabel: UILabel = {
        let label = UILabel()
        label.text = "B: 0"
        label.font = .systemFont(ofSize: 14)
        return label
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("취소", for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 8
        return button
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("확인", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(hex: "FF6A6A") // 메인 컬러
        button.layer.cornerRadius = 8
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        view.addSubview(containerView)
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(colorPreview)
        containerView.addSubview(hexLabel)
        
        containerView.addSubview(redLabel)
        containerView.addSubview(redSlider)
        containerView.addSubview(greenLabel)
        containerView.addSubview(greenSlider)
        containerView.addSubview(blueLabel)
        containerView.addSubview(blueSlider)
        
        containerView.addSubview(cancelButton)
        containerView.addSubview(confirmButton)
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.85)
            make.height.equalTo(380)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview()
        }
        
        colorPreview.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(80)
        }
        
        hexLabel.snp.makeConstraints { make in
            make.top.equalTo(colorPreview.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.height.equalTo(24)
        }
        
        redLabel.snp.makeConstraints { make in
            make.top.equalTo(hexLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(20)
            make.width.equalTo(50)
        }
        
        redSlider.snp.makeConstraints { make in
            make.centerY.equalTo(redLabel)
            make.leading.equalTo(redLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        greenLabel.snp.makeConstraints { make in
            make.top.equalTo(redLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(20)
            make.width.equalTo(50)
        }
        
        greenSlider.snp.makeConstraints { make in
            make.centerY.equalTo(greenLabel)
            make.leading.equalTo(greenLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        blueLabel.snp.makeConstraints { make in
            make.top.equalTo(greenLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(20)
            make.width.equalTo(50)
        }
        
        blueSlider.snp.makeConstraints { make in
            make.centerY.equalTo(blueLabel)
            make.leading.equalTo(blueLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(44)
            make.width.equalTo(confirmButton.snp.width)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(44)
            make.leading.equalTo(cancelButton.snp.trailing).offset(12)
        }
    }
    
    private func setupActions() {
        redSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        greenSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        blueSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func sliderValueChanged() {
        let red = CGFloat(redSlider.value) / 255.0
        let green = CGFloat(greenSlider.value) / 255.0
        let blue = CGFloat(blueSlider.value) / 255.0
        
        selectedColor = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        colorPreview.backgroundColor = selectedColor
        
        redLabel.text = "R: \(Int(redSlider.value))"
        greenLabel.text = "G: \(Int(greenSlider.value))"
        blueLabel.text = "B: \(Int(blueSlider.value))"
        
        // 16진수 코드 업데이트
        selectedHexCode = String(
            format: "%02X%02X%02X",
            Int(redSlider.value),
            Int(greenSlider.value),
            Int(blueSlider.value)
        )
        hexLabel.text = "#\(selectedHexCode)"
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func confirmButtonTapped() {
        onColorSelected?(selectedColor, selectedHexCode)
        dismiss(animated: true)
    }
}
