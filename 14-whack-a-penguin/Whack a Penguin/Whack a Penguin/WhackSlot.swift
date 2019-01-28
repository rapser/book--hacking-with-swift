//
//  WhackSlot.swift
//  Whack a Penguin
//
//  Created by Brian Sipple on 1/28/19.
//  Copyright © 2019 Brian Sipple. All rights reserved.
//

import SpriteKit
import UIKit

class WhackSlot: SKNode {
    enum NodeName: String {
        case goodPenguin = "good-penguin"
        case evilPenguin = "evil-penguin"
    }
    
    var penguinNode: SKSpriteNode!
    var isShowingPenguin: Bool = false
    var isWhacked: Bool = false
    
    var penguinTextureName: String {
        return isPenguinGood ? "penguinGood" : "penguinEvil"
    }
    
    var isPenguinGood = false {
        didSet {
            penguinNode.texture = SKTexture(imageNamed: penguinTextureName)
            penguinNode.name = isPenguinGood ? NodeName.goodPenguin.rawValue : NodeName.evilPenguin.rawValue
        }
    }
    
    
    func setup(at position: CGPoint) {
        self.position = position
        
        let hole = SKSpriteNode(imageNamed: "whackHole")
        
        setupPenguin(at: position)
        self.addChild(hole)
    }
    
    
    func show(for duration: Double) {
        guard !isShowingPenguin else { return }
        
        isPenguinGood = Double.random(in: 0...1) >= 0.3333
        
        showPenguin(for: duration)
    }
    
    
    private func showPenguin(for duration: Double) {
        let showAction = SKAction.moveBy(x: 0, y: 80, duration: 0.05)
        
        penguinNode.run(showAction)
        isShowingPenguin = true
        isWhacked = false
    }
    
    
    private func setupPenguin(at position: CGPoint) {
        let cropNode = SKCropNode()
        penguinNode = SKSpriteNode(imageNamed: "penguinGood")
        
        cropNode.position = CGPoint(x: 0, y: 15)
        cropNode.zPosition = 1
        cropNode.maskNode = SKSpriteNode(imageNamed: "whackMask")
        
        penguinNode.position = CGPoint(x: 0, y: -90)
        penguinNode.name = NodeName.goodPenguin.rawValue
        
        cropNode.addChild(penguinNode)
        
        self.addChild(cropNode)
    }
}
