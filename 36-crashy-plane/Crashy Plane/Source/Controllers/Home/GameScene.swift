//
//  GameScene.swift
//  Crashy Plane
//
//  Created by Brian Sipple on 3/2/19.
//  Copyright © 2019 Brian Sipple. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    enum GameplayState {
        case inProgress
        case playerDied
    }
    
    // MARK: - Instance Properties
    
    let rockDistance = 70
    
    lazy var player = makePlayer()
    lazy var scoreLabel = makeScoreLabel()
    lazy var rockTexture = SKTexture(imageNamed: "rock")
    lazy var backgroundTexture = SKTexture(imageNamed: "background")
    lazy var groundTexture = SKTexture(imageNamed: "ground")
    
    
    var currentScore = 0 {
        didSet {
            scoreLabel.text = "SCORE: \(currentScore)"
        }
    }
    
    // MARK: - Lifecycle
    
    override func didMove(to view: SKView) {
        currentScore = 0
        
        addChild(player)
        addChild(scoreLabel)
        
        createSky()
        createBackground()
        createGround()
        startGame()
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    
    // MARK: - Methods
    
    func startGame() {
        let create = SKAction.run { [weak self] in
            self?.createRocks()
        }
        
        let runSequence = SKAction.sequence([
            create,
            SKAction.wait(forDuration: 3)
        ])
        
        run(SKAction.repeatForever(runSequence))
    }
    
    
    /**
        1. Create top and bottom rock sprites. They are both the same graphic, but we're going to rotate the
        top one and flip it horizontally so that the two rocks form a spiky death for the player.
     
        2. Create a third sprite that is a large red rectangle. This will be positioned just after the rocks
        and will be used to track when the player has passed through the rocks safely – if they touch that
        red rectangle, they should score a point. (Don't worry, we'll make it invisible later!)
     
        3. Use Swift’s random number generation to generate a number in a range. This will be used
        to determine where the safe gap in the rocks should be.
     
        4. Position the rocks just off the right edge of the screen, then animate them
        across to the left edge. When they are safely off the left edge, remove them from the game.
     */
    func createRocks() {
        let rockContainer = SKSpriteNode()
        let (top: topRock, bottom: bottomRock, clearanceMarker) = createRockSet()
        
        let slideSequence = SKAction.sequence([
            SKAction.moveBy(x: -(frame.width + topRock.size.width * 2), y: 0, duration: Duration.rockSlide),
            SKAction.removeFromParent()
        ])
        
        [topRock, bottomRock, clearanceMarker].forEach { rockContainer.addChild($0) }
        
        rockContainer.run(slideSequence)
        addChild(rockContainer)
    }
    
    func createRockSet() -> (top: SKSpriteNode, bottom: SKSpriteNode, clearanceMarker: SKSpriteNode) {
        let topRock = SKSpriteNode(texture: rockTexture)
        let bottomRock = SKSpriteNode(texture: rockTexture)
        let rockXPos = frame.width + topRock.frame.width
        
        for rock in [topRock, bottomRock] {
            rock.zPosition = ZPosition.rocks
            rock.position.x = rockXPos
            rock.yScale = 1.5
        }
        
        let maxYFocalPoint = frame.maxY * 0.43
        let minYFocalPoint = frame.maxY * 0.1
        let yFocalPoint = CGFloat.random(in: minYFocalPoint...maxYFocalPoint)
        
        topRock.position.y = (yFocalPoint + CGFloat(rockDistance) + topRock.size.height)
        bottomRock.position.y = (yFocalPoint - CGFloat(rockDistance))

        topRock.zRotation = .pi
        topRock.xScale = -1
        
        let clearanceMarker = SKSpriteNode(color: .red, size: CGSize(width: player.size.width, height: frame.height))
        clearanceMarker.name = NodeName.clearanceMarker
        clearanceMarker.position = CGPoint(x: rockXPos + (topRock.size.width / 2) + (clearanceMarker.size.width / 2), y: frame.midY)
        
        return (topRock, bottomRock, clearanceMarker)
    }
    
    
    func createSky() {
        let topSky = SKSpriteNode(color: SceneColor.topSky, size: CGSize(width: frame.width, height: frame.height * 0.67))
        let bottomSky = SKSpriteNode(color: SceneColor.bottomSky, size: CGSize(width: frame.width, height: frame.height * 0.33))
        
        [topSky, bottomSky].forEach { (node) in
            node.anchorPoint = CGPoint(x: 0.5, y: 1)
            node.position = CGPoint(x: frame.midX, y: frame.height)
            node.zPosition = ZPosition.sky
            
            addChild(node)
        }
    }
    
    
    func createBackground() {
        let backgroundSize = backgroundTexture.size()
        
        let slideSequence = SKAction.sequence([
            SKAction.moveBy(x: -backgroundSize.width, y: 0, duration: Duration.backgroundSlide),
            SKAction.moveBy(x: backgroundSize.width, y: 0, duration: 0)
        ])
        
        for i in 0...1 {
            let background = SKSpriteNode(texture: backgroundTexture)
            let xPos = (CGFloat(i) * backgroundTexture.size().width) - CGFloat(1 * i) // small overlap for second piece
            
            background.anchorPoint = CGPoint.zero
            background.zPosition = ZPosition.slidingBackground
            background.position = CGPoint(x: xPos, y: 10)
            
            background.run(SKAction.repeatForever(slideSequence))
            
            addChild(background)
        }
    }
    
    
    func createGround() {
        let groundSize = groundTexture.size()
        
        let slideSequence = SKAction.sequence([
            SKAction.moveBy(x: -groundSize.width, y: 0, duration: Duration.groundSlide),
            SKAction.moveBy(x: groundSize.width, y: 0, duration: 0)
        ])
        
        for i in 0...1 {
            let xPos = (groundSize.width / 2) + (CGFloat(i) * groundSize.width)
            let yPos = groundSize.height / 2
            let ground = SKSpriteNode(texture: groundTexture)
            
            ground.position = CGPoint(x: xPos, y: yPos)
            ground.zPosition = ZPosition.ground
            ground.run(SKAction.repeatForever(slideSequence))
            
            addChild(ground)
        }
    }
    
    
    
    // MARK: - Private functions
    
    /**
     Create the player node, starting from the first-phase animation sprite
     and positioning it most of the way up and most of the way to the left of
     the screen.
     
     We'll also configure it to animate through each propeller phase as fast as possible
     */
    private func makePlayer() -> SKSpriteNode {
        let texture1 = SKTexture(imageNamed: "player-1")
        let texture2 = SKTexture(imageNamed: "player-2")
        let texture3 = SKTexture(imageNamed: "player-3")

        let player = SKSpriteNode(texture: texture1)
        let propellerAnimation = SKAction.animate(with: [texture1, texture2, texture3, texture2], timePerFrame: 0.01)
        
        player.zPosition = ZPosition.player
        player.position = CGPoint(x: frame.width * 0.16667, y: frame.height * 0.75)
        
        player.run(SKAction.repeatForever(propellerAnimation))
        
        return player
    }
    
    private func makeScoreLabel() -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "EuphemiaUCAS-Bold")
        
        label.fontSize = 24
        label.position = CGPoint(x: frame.midX, y: frame.maxY - 60)
        label.fontColor = .black
        
        return label
    }
}
