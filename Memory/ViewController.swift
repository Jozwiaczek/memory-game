//
//  ViewController.swift
//  Memory
//
//  Created by Jakub Jóźwiak on 10/12/2019.
//  Copyright © 2019 Jakub Jóźwiak. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var actionBtn: UIButton!
    @IBOutlet weak var levelControl: UISlider!
    @IBOutlet weak var recordLabel: UILabel!
    @IBOutlet weak var mainImg: UIImageView!
    @IBOutlet var imgCollection: [UIImageView]!
    
    let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
    let defaults = UserDefaults.standard
    let questionImage: UIImage = UIImage(systemName: "questionmark")!
    
    var cardShowTime:Double = 0.0
    var gameState = false
    var imgToFind = ""
    var imagesLabel = ["swift", "java", "python", "c", "cSharp", "cPlusPlus", "go", "js"]
    var cardMap = [UIImageView:String]()
    var checkedCardMap = [UIImageView:String]()
    var lastClickStamp = 0
    
    var level = 1 {
        didSet {
            levelLabel.text = String(level)
            recordLabel.text = String(defaults.integer(forKey: "record\(level)"))
        }
    }
    
    var score = 0 {
        didSet {
            scoreLabel.text = String(score)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notificationFeedbackGenerator.prepare()
        actionBtn.layer.cornerRadius = 10
        recordLabel.text = String(defaults.integer(forKey: "record1"))
        
//        Reset records
//        =============
//        for n in 1...5 {
//            defaults.set(0, forKey: "record\(n)")
//        }
        
        for imageView in imgCollection {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapHandle(tapGestureRecognizer:)))
            imageView.isUserInteractionEnabled = true
            imageView.addGestureRecognizer(tapGestureRecognizer)
        }

        // Blur effect with modal
        view.addSubview(visualEffectView)
        visualEffectView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        visualEffectView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        visualEffectView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        visualEffectView.alpha = 0
    }
    
    @IBAction func levelControl(_ sender: UISlider) {
        let roundedValue = round(sender.value)
        sender.value = roundedValue
        level = Int(sender.value)
    }
    
    @IBAction func pressedActionBtn(_ sender: UIButton) {
        if !gameState {
            startGame()
        } else {
            stopGame()
        }
    }
    
    func startGame() {
        actionBtn.isEnabled = false
        actionBtn.setTitle("It is time...", for: .normal)
        actionBtn.backgroundColor = UIColor.systemYellow
        
        cardShowTime = Double(6-level)/2
        levelControl.isEnabled = false
        
        imgToFind = imagesLabel.randomElement()!
        
        for imageView in imgCollection {
            cardMap[imageView] = imagesLabel.randomElement()
            imagesLabel.removeAll { (value) -> Bool in
                value == cardMap[imageView]
            }
        }
             
        mainImg.image = UIImage(named: String(imgToFind))
        mainImg.layer.borderWidth = 2
        mainImg.layer.borderColor = UIColor.systemPink.cgColor
        mainImg.layer.cornerRadius = 20
        
        _ = cardMap.map { (img: UIImageView, name: String) -> Void in
            img.image = UIImage(named: name)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + cardShowTime) {
            _ = self.cardMap.map { (img: UIImageView, name: String) -> Void in
                img.image = self.questionImage
                self.gameState = true
                self.actionBtn.setTitle("End Game", for: .normal)
                self.actionBtn.backgroundColor = UIColor.systemPink
                self.actionBtn.isEnabled = true
                self.lastClickStamp = Date().getSec()
            }
        }
        
    }
    
    func stopGame() {
        imagesLabel.append(imgToFind)
        levelControl.isEnabled = true
        actionBtn.setTitle("Start Game", for: .normal)
        actionBtn.backgroundColor = UIColor.systemGreen
        score = 0
        mainImg.image = questionImage
        mainImg.layer.borderWidth = 0
        mainImg.layer.borderColor = nil
        mainImg.layer.cornerRadius = 0
        
        _ = checkedCardMap.map { (img: UIImageView, name: String) -> Void in
            imagesLabel.append(name)
            img.image = questionImage
        }
        
        checkedCardMap.removeAll()
        _ = cardMap.map { (img: UIImageView, name: String) -> Void in
            imagesLabel.append(name)
            img.image = questionImage
        }
        cardMap.removeAll()
        
        gameState = false
    }
    
    @objc func imageTapHandle(tapGestureRecognizer: UITapGestureRecognizer) {
        if (gameState) {
            let tappedImage = tapGestureRecognizer.view as! UIImageView
            let tappedLabel = cardMap[tappedImage]
            
            if(tappedLabel == nil) { return }
            
            tappedImage.image = UIImage(named: String(tappedLabel!))
            
            if (tappedLabel == imgToFind) {
                let clickStamp: Int = Date().getSec()
                let pickTime = (clickStamp - lastClickStamp)
                
                score += ((10/level)*10) - pickTime
                scoreLabel.textColor = .systemGreen
                UIView.animate(withDuration: 0.2) {
                    self.scoreLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                    self.mainImg.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.scoreLabel.textColor = nil
                    UIView.animate(withDuration: 0.2) {
                        self.scoreLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                        self.mainImg.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    }
                }
                cardMap.removeValue(forKey: tappedImage)
                checkedCardMap[tappedImage] = tappedLabel
                if (cardMap.count > 0) {
                    imgToFind = cardMap.randomElement()!.value
                    mainImg.image = UIImage(named: String(imgToFind))
                    notificationFeedbackGenerator.notificationOccurred(.success)
                } else {
                    let record = defaults.integer(forKey: "record\(level)")
                    let recordToCompare = record==0 ? -Int(INT32_MAX) : record
                    if (recordToCompare < score) {
                        defaults.set(score, forKey: "record\(level)")
                        recordLabel.text = String(score)
                    }
                    handleShowPopUp()
                    stopGame()
                }
                
            }
            else {
                scoreLabel.textColor = .systemPink
                UIView.animate(withDuration: 0.2) {
                    self.scoreLabel.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.scoreLabel.textColor = nil
                    UIView.animate(withDuration: 0.2) {
                        self.scoreLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    }
                }
                score -= (level*2)*10
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    tappedImage.image = self.questionImage
                }
            }
        }
    }
    
    lazy var popUpWindow: PopUpWindow = {
        let view = PopUpWindow()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.delegate = self as PopUpDelegate
        return view
    }()
    
    let visualEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .light)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    @objc func handleShowPopUp() {
        view.addSubview(popUpWindow)
        popUpWindow.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30).isActive = true
        popUpWindow.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        popUpWindow.heightAnchor.constraint(equalToConstant: 300).isActive = true
        popUpWindow.widthAnchor.constraint(equalToConstant: view.frame.width - 64).isActive = true
        
        popUpWindow.showScore = score
                
        popUpWindow.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        popUpWindow.alpha = 0
        
        UIView.animate(withDuration: 0.5) {
            self.visualEffectView.alpha = 1
            self.popUpWindow.alpha = 1
            self.popUpWindow.transform = CGAffineTransform.identity
        }
    }
    
}

extension Date {
    func getSec() -> Int! {
        return Int(self.timeIntervalSince1970)
    }
}

extension ViewController: PopUpDelegate {
    func handleDismissal() {
        UIView.animate(withDuration: 0.5, animations: {
            self.visualEffectView.alpha = 0
            self.popUpWindow.alpha = 0
            self.popUpWindow.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }) { (_) in
            self.popUpWindow.removeFromSuperview()
        }
    }
}
