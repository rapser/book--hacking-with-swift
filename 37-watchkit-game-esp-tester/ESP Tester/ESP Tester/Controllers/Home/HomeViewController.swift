//
//  ViewController.swift
//  ESP Tester
//
//  Created by Brian Sipple on 3/5/19.
//  Copyright © 2019 Brian Sipple. All rights reserved.
//

import UIKit
import AVFoundation
import WatchConnectivity


class HomeViewController: UIViewController {
    @IBOutlet var cardContainer: UIView!
    @IBOutlet var gradientView: UIView!
    
    enum CardState {
        case allFlat
        case flipping
    }
    
    
    // MARK: - Instance Properties
    
    var currentCardState = CardState.allFlat
    var cardViewControllers: [CardViewController] = []
    var lastMessageSentAt: CFAbsoluteTime = 0
    
    lazy var cardPositions = makeCardPositions()
    lazy var cardImages = makeCardImages()
    lazy var particleEmitter = makeParticleEmitter()
    lazy var backgroundMusic: AVAudioPlayer? = makeAudioPlayer()
    
    lazy var watchConnectivitySession: WCSession? = {
        guard WCSession.isSupported() else { return nil }
        
        let session = WCSession.default
        session.delegate = self
        return session
    }()
    
    var isForceTouchEnabled: Bool {
        return view.traitCollection.forceTouchCapability == .available
    }
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        watchConnectivitySession?.activate()
        
        setupBackground()
        loadCards()
        setupWiggling()
        backgroundMusic?.play()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let instructions = """
        Please ensure your Apple Watch is configured correctly. On your iPhone, \
        launch Apple's 'Watch' configuration app then choose General > Wake Screen.
        
        On that screen, please disable Wake Screen On Wrist Raise, then select \
        Wake For 70 Seconds. On your Apple Watch, please swipe up on your watch \
        face and enable Silent Mode. You're done!
        """
        
        let alertController = UIAlertController(title: "Adjust your settings", message: instructions, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alertController, animated: true)
    }
    
    
    // MARK: - Methods
    
    @objc func loadCards() {
        removeCardsInView()
        cardImages.shuffle()
        
        for (index, position) in cardPositions.enumerated() {
            let cardViewController = CardViewController()
            let cardImage = cardImages[index]
            
            cardViewController.delegate = self
            
            // use view controller containment...
            addChild(cardViewController)
            
            // ...AND add the VC's view to our container view
            cardContainer.addSubview(cardViewController.view)
            cardViewController.didMove(toParent: self)
            
            cardViewController.view.center = position
            cardViewController.frontImageView.image = cardImage
            
            // if the new card is a star, mark is as "correct"
            if cardImage.accessibilityIdentifier == "Star" {
                cardViewController.isCorrect = true
            }
            
            cardViewControllers.append(cardViewController)
        }
        
        currentCardState = .allFlat
    }
    
    
    func removeCardsInView() {
        for card in cardViewControllers {
            card.view.removeFromSuperview()
            card.removeFromParent()
        }
        
        cardViewControllers.removeAll(keepingCapacity: true)
    }
    
    
    func setupBackground() {
        view.backgroundColor = .red
        
        UIView.animate(
            withDuration: 20,
            delay: 0,
            options: [.allowUserInteraction, .autoreverse, .repeat],
            animations: { [weak self] in
                self?.view.backgroundColor = .blue
            }
        )
        
        gradientView.layer.addSublayer(particleEmitter)
    }
    
    
    func setupWiggling() {
        cardViewControllers.forEach({ card in
            perform(#selector(wiggle), with: card, afterDelay: Double.random(in: 0...10))
        })
    }
    
    @objc func wiggle(_ card: CardViewController) {
        card.wiggle()
        
        if Int.random(in: 0...1) == 1 {
            perform(#selector(wiggle), with: card, afterDelay: Double.random(in: 1...2))
        } else {
            perform(#selector(wiggle), with: card, afterDelay: Double.random(in: 7...10))
        }
    }
    
    
    // MARK: - Event handling
    
    func cardTapped(_ tappedCard: CardViewController) {
        guard currentCardState == .allFlat else { return }
        
        currentCardState = .flipping
        
        for card in cardViewControllers {
            if card == tappedCard {
                card.flipToReveal()
                card.perform(#selector(card.fadeAway), with: nil, afterDelay: 1)
            } else {
                card.fadeAway()
            }
        }
        
        perform(#selector(loadCards), with: nil, afterDelay: 2)
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        guard let touch = touches.first else { return }
        
        if let touchedCard = card(from: touch) {
            if isForceTouchEnabled && touch.force == touch.maximumPossibleForce {
                touchedCard.frontImageView.image = UIImage(named: "cardStar")
                touchedCard.isCorrect = true
            }
            
            if touchedCard.isCorrect {
                sendWatchMessage()
            }
        }
    }
    
    
    // MARK: - Private functions
    
    private func makeCardPositions() -> [CGPoint] {
        let cardWidth = Dimension.Card.width
        let cardHeight = Dimension.Card.height
        let xSpacing = 10
        let ySpacing = 10
        
        var positions: [CGPoint] = []
        
        for row in 0...1 {
            let yPos = (cardHeight / 2) + (cardHeight * row) + (ySpacing * row) + 15
            
            positions += [
                CGPoint(x: (cardWidth / 2) + (cardWidth * 0) + (xSpacing * 1) + 15, y: yPos),
                CGPoint(x: (cardWidth / 2) + (cardWidth * 1) + (xSpacing * 2) + 15, y: yPos),
                CGPoint(x: (cardWidth / 2) + (cardWidth * 2) + (xSpacing * 3) + 15, y: yPos),
                CGPoint(x: (cardWidth / 2) + (cardWidth * 3) + (xSpacing * 4) + 15, y: yPos),
            ]
        }
        
        return positions
    }
    
    
    private func makeCardImages() -> [UIImage] {
        return [
            "Circle", "Circle", "Cross", "Cross", "Lines", "Lines", "Square", "Star"
        ].map {
            let image = UIImage(named: "card\($0)")!
            image.accessibilityIdentifier = $0
            
            return image
        }
    }
    
    
    private func makeParticleEmitter() -> CAEmitterLayer {
        let emitterLayer = CAEmitterLayer()
        
        emitterLayer.position = CGPoint(x: view.frame.midX, y: view.frame.minY - 50)
        emitterLayer.emitterShape = .line
        emitterLayer.emitterSize = CGSize(width: view.frame.width, height: 1)
        emitterLayer.renderMode = .additive
        
        let emitterCell = CAEmitterCell()
        emitterCell.birthRate = 2
        emitterCell.lifetime = 5.0
        emitterCell.velocity = 100
        emitterCell.velocityRange = 50
        emitterCell.emissionLongitude = .pi
        emitterCell.spinRange = 5
        emitterCell.scale = 0.5
        emitterCell.scaleRange = 0.25
        emitterCell.color = UIColor(white: 1, alpha: 0.1).cgColor
        emitterCell.alphaSpeed = -0.025
        emitterCell.contents = UIImage(named: "particle")?.cgImage
        
        emitterLayer.emitterCells = [emitterCell]
        
        return emitterLayer
    }
    
    
    private func makeAudioPlayer() -> AVAudioPlayer? {
        if let audioURL = Bundle.main.url(forResource: "PhantomFromSpace", withExtension: "mp3") {
            do {
                let player = try AVAudioPlayer(contentsOf: audioURL)
                player.numberOfLoops = -1
                
                return player
            } catch {
                 print("Error while trying to load background music audio: \(error.localizedDescription)")
            }
        } else {
            print("Couldn't find URL for \"PhantomFromSpace.mp3\"")
        }
        
        return nil
    }
    
    private func card(from touch: UITouch) -> CardViewController? {
        let touchLocation = touch.location(in: cardContainer)
        
        return cardViewControllers.first(where: { $0.view.frame.contains(touchLocation) })
    }
}


// MARK: - WCSessionDelegate
extension HomeViewController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // TODO:
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        // TODO:
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // TODO:
    }
    
    func sendWatchMessage() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        
        if lastMessageSentAt + 0.5 > currentTime {
            return
        }
        
        if watchConnectivitySession?.isReachable ?? false {
            let message = ["Dummy Message": "Hello, Watch"]
            watchConnectivitySession?.sendMessage(message, replyHandler: nil)
        }
        
        lastMessageSentAt = CFAbsoluteTimeGetCurrent()
    }
}

