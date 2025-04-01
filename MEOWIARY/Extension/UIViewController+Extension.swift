//
//  UIViewController+Extension.swift
//  MEOWIARY
//
//  Created by 권우석 on 4/2/25.
//

import UIKit
import SnapKit

extension UIViewController {
    
    
    func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    

    private static let toastViewTag = UUID().hashValue // 토스트가 겹치지 않고 이전거는 사라지도록 UUID를 사용하고 싶었는데 hashvalue를 이용하면 정수로 태그로 사용가능쓰
    
    func showToast(message: String, duration: TimeInterval = 2.0) {
        if let existingToast = view.viewWithTag(UIViewController.toastViewTag) {
            existingToast.removeFromSuperview()
        }
        
        let toastView = UIView()
        toastView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastView.layer.cornerRadius = 10
        toastView.clipsToBounds = true
        toastView.alpha = 0
        toastView.tag = UIViewController.toastViewTag
        
        let toastLabel = UILabel()
        toastLabel.textColor = .white
        toastLabel.font = .systemFont(ofSize: 14)
        toastLabel.textAlignment = .center
        toastLabel.numberOfLines = 0
        toastLabel.text = message
        
        view.addSubview(toastView)
        toastView.addSubview(toastLabel)
        
        toastView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-100)
            make.width.lessThanOrEqualToSuperview().offset(-40)
        }
        
        toastLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        
        
        UIView.animate(withDuration: 0.3, animations: {
            toastView.alpha = 1
        }, completion: { _ in
            
            UIView.animate(withDuration: 0.3, delay: duration, options: .curveEaseOut, animations: {
                toastView.alpha = 0
            }, completion: { _ in
                toastView.removeFromSuperview()
            })
        })
    }
}
       

