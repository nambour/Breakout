//
//  GameScene.swift
//  Breakout
//
//  Created by Rui Li on 24/9/18.
//  Copyright © 2018 Rui Li. All rights reserved.
//

import SpriteKit
import CoreGraphics
import Foundation
import GameplayKit

// Preset Node name
enum NodeName: String {
    case playerBall
    case playerPaddle
    case NPCBall
    case NPCPaddle
    case brick
    case border
    case playerBottom
    case NPCBottom
    case gameMessage
}

// Preset Rainbow colors for the bricks
enum RainbowBrickName: Int {
    case red = 0
    case organe
    case yellow
    case green
    case indigo
    case blue
    case violet
    
    func Get(index: Int) -> String {
        switch index {
        case 0:
            return "brick_red"
        case 1:
            return "brick_orange"
        case 2:
            return "brick_yellow"
        case 3:
            return "brick_green"
        case 4:
            return "brick_indigo"
        case 5:
            return "brick_blue"
        case 6:
            return "brick_violet"
        default:
            return "No MATCHING"
        }
    }
}


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Number of columns and rows of the bricks
    let BrickCol = 9
    let BrickRow = 7
    
    // Preset code for collision detection
    let PlayerBallCategory  : UInt32 = 0x1 << 0
    let BottomCategory      : UInt32 = 0x1 << 1
    let BrickCategory       : UInt32 = 0x1 << 2
    let PlayerPaddleCategory: UInt32 = 0x1 << 3
    let BorderCategory      : UInt32 = 0x1 << 4
    
    
    var isFingerOnPaddle = false
    
    // Game state machine
    lazy var gameState: GKStateMachine = GKStateMachine(states: [
        WaitingForTap(scene: self),
        Playing(scene: self),
        GameOver(scene: self)])
    
    
    var gameWon : Bool = false {
        didSet {
            let gameOver = childNode(withName: NodeName.gameMessage.rawValue) as? SKLabelNode
            // If gameWon state is changed, change the message accordingly
            gameOver?.text = gameWon ? "YOU WON" : "GAME OVER"
            gameOver?.removeAllActions()
            let action = SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.fadeOut(withDuration: 1),
                    SKAction.fadeIn(withDuration: 1)]))
            gameOver?.run(action)
        }
    }
    
    
    // MARK: - Game main functionality

    /// <#Description#>
    ///
    /// - Parameter view: <#view description#>
    override func didMove(to view: SKView) {
        super.didMove(to: view)
    
        SetupScene()
        CreatBottomLine()
        AddPlayerBall()
        AddPlayerPaddle()
        AddBricks()
        AddGameMessage()
        
        gameState.enter(WaitingForTap.self)
    }
    
    /// <#Description#>
    ///
    /// - Parameter currentTime: <#currentTime description#>
    override func update(_ currentTime: TimeInterval) {
        gameState.update(deltaTime: currentTime)
    }
    
    /// <#Description#>
    ///
    /// - Parameter contact: <#contact description#>
    func didBegin(_ contact: SKPhysicsContact) {
        
        if gameState.currentState is Playing {
            
            var firstBody: SKPhysicsBody
            var secondBody: SKPhysicsBody
            
            if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
                firstBody = contact.bodyA
                secondBody = contact.bodyB
            }
            else {
                firstBody = contact.bodyB
                secondBody = contact.bodyA
            }
            
            
            if firstBody.categoryBitMask == PlayerBallCategory && secondBody.categoryBitMask == BottomCategory {
                gameState.enter(GameOver.self)
                gameWon = false
                print("Hit bottom. First contact has been made.")
            }
            
            if firstBody.categoryBitMask == PlayerBallCategory && secondBody.categoryBitMask == BrickCategory {
                breakBrick(node: secondBody.node!)
            }
        }
        
        if isGameWon() {
            gameState.enter(GameOver.self)
            gameWon = true
        }
    }
    
    
    // MARK: -
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - touches: <#touches description#>
    ///   - event: <#event description#>
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState.currentState {
            
        case is WaitingForTap:
            gameState.enter(Playing.self)
            isFingerOnPaddle = true
            
        case is Playing:
            isFingerOnPaddle = true
            
        case is GameOver:
            let newScene = GameScene(fileNamed:"GameScene")
            newScene!.scaleMode = .aspectFit
            self.view?.presentScene(newScene!)
            
        default:
            break
        }
    }
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - touches: <#touches description#>
    ///   - event: <#event description#>
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isFingerOnPaddle {
            let touch = touches.first
            let touchLocation = touch!.location(in: self)
            let previousLocation = touch!.previousLocation(in: self)
            
            let paddle = childNode(withName: NodeName.playerPaddle.rawValue) as! SKSpriteNode
            var paddleX = paddle.position.x + touchLocation.x - previousLocation.x
            
            // Confine paddle movement
            paddleX = max(paddleX, paddle.frame.width / 2)
            paddleX = min(paddleX, frame.width - paddle.frame.width/2)
            
            paddle.position = CGPoint(x: paddleX, y: paddle.position.y)
        }
    }
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - touches: <#touches description#>
    ///   - event: <#event description#>
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isFingerOnPaddle = false
    }
    
    
    // MARK: -
    
    /// <#Description#>
    func SetupScene() {
        self.backgroundColor = .black
        self.scaleMode = .aspectFit
        
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        self.physicsBody?.friction = 0
        self.physicsBody?.restitution = 1
        self.physicsBody?.usesPreciseCollisionDetection = true
        self.physicsBody?.categoryBitMask = BorderCategory
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
    }
    
    /// <#Description#>
    func AddPlayerBall() {
        let playerBall = Ball(from: "ball_aqua")
        playerBall.name = NodeName.playerBall.rawValue
        playerBall.position = CGPoint(x: frame.midX, y: frame.maxY*0.2)
        playerBall.physicsBody?.categoryBitMask = PlayerBallCategory
        playerBall.physicsBody?.contactTestBitMask = BottomCategory
        playerBall.physicsBody?.contactTestBitMask = BottomCategory | BrickCategory
        self.addChild(playerBall)
    }
    
    /// <#Description#>
    func AddPlayerPaddle() {
        let playerPaddle = Paddle(from: "paddle_aqua")
        playerPaddle.name = NodeName.playerPaddle.rawValue
        playerPaddle.position = CGPoint(x: frame.midX, y: frame.maxY*0.2)
        playerPaddle.physicsBody?.categoryBitMask = PlayerPaddleCategory
        self.addChild(playerPaddle)
    }
    
    /// <#Description#>
    func AddBricks() {
        
        let brickWidth = SKSpriteNode(imageNamed: "brick_red").size.width
        let brickHeight = SKSpriteNode(imageNamed: "brick_red").size.height
        let totalHeight = brickHeight * CGFloat(BrickRow)
        let color = RainbowBrickName.red
        
        for i in 0..<BrickCol {
            for n in 0..<BrickRow {
                let imageName = color.Get(index: n)
                let brick = Brick(from: imageName)
                brick.name = NodeName.brick.rawValue
                brick.position = CGPoint(
                    x: brickWidth/2 + CGFloat(i) * brickWidth,
                    y: (self.size.height - totalHeight) / 2 + CGFloat(n) * brickHeight)
                brick.physicsBody?.categoryBitMask = BrickCategory
                self.addChild(brick)
            }
        }
    }
    
    /// <#Description#>
    func CreatBottomLine() {
        let bottomRect = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: 5)
        let bottom = SKNode()
        bottom.name = NodeName.playerBottom.rawValue
        bottom.physicsBody = SKPhysicsBody(edgeLoopFrom: bottomRect)
        bottom.physicsBody?.categoryBitMask = BottomCategory
        self.addChild(bottom)
    }
    
    /// <#Description#>
    func AddGameMessage() {
        let gameMessage = SKLabelNode(text: "TAP TO START")
        gameMessage.name = NodeName.gameMessage.rawValue
        gameMessage.position = CGPoint(x: frame.midX, y: frame.maxY*0.7)
        gameMessage.fontName = "AppleSDGothicNeo-Thin"
        gameMessage.fontSize = 50
        gameMessage.zPosition = 5
        addChild(gameMessage)
    }
    
    /// <#Description#>
    ///
    /// - Parameter node: <#node description#>
    func breakBrick(node: SKNode) {
        // TODO visual effects
        node.removeFromParent()
    }
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - from: <#from description#>
    ///   - to: <#to description#>
    /// - Returns: <#return value description#>
    func randomFloat(from: CGFloat, to: CGFloat) -> CGFloat {
        let rand: CGFloat = CGFloat(Float(arc4random()) / 0xFFFFFFFF)
        return (rand) * (to - from) + from
    }
    
    /// <#Description#>
    ///
    /// - Returns: <#return value description#>
    func isGameWon() -> Bool {
        var numberOfBricks = 0
        self.enumerateChildNodes(withName: NodeName.brick.rawValue) {
            node, stop in
            numberOfBricks = numberOfBricks + 1
        }
        return numberOfBricks == 0
    }
}



// MARK: -

/// <#Description#>
class WaitingForTap: GKState {
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        scene.childNode(withName: NodeName.gameMessage.rawValue)!.removeAllActions()
        let action = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeOut(withDuration: 1),
            SKAction.fadeIn(withDuration: 1)]))
        scene.childNode(withName: NodeName.gameMessage.rawValue)!.run(action)
    }
    
    override func willExit(to nextState: GKState) {
        if nextState is Playing {
            scene.childNode(withName: NodeName.gameMessage.rawValue)!.removeAllActions()
            let action = SKAction.fadeOut(withDuration: 0.5)
            scene.childNode(withName: NodeName.gameMessage.rawValue)!.run(action)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Playing.Type
    }
    
}

/// <#Description#>
class Playing: GKState {
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    func randomDirection() -> CGFloat {
        let speedFactor: CGFloat = 3.0
        if scene.randomFloat(from: 0.0, to: 100.0) >= 50 {
            return -speedFactor
        } else {
            return speedFactor
        }
    }
    
    override func didEnter(from previousState: GKState?) {
        if previousState is WaitingForTap {
            let ball = scene.childNode(withName: NodeName.playerBall.rawValue) as! SKSpriteNode
            ball.physicsBody!.applyImpulse(CGVector(dx: randomDirection(), dy: randomDirection()))
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        let ball = scene.childNode(withName: NodeName.playerBall.rawValue) as! SKSpriteNode
        let maxSpeed: CGFloat = 400.0
        
        let xSpeed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx)
        let ySpeed = sqrt(ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
        
        let speed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx + ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
        
        if xSpeed <= 10.0 {
            ball.physicsBody!.applyImpulse(CGVector(dx: randomDirection(), dy: 0.0))
        }
        if ySpeed <= 10.0 {
            ball.physicsBody!.applyImpulse(CGVector(dx: 0.0, dy: randomDirection()))
        }
        
        if speed > maxSpeed {
            ball.physicsBody!.linearDamping = 0.4
        } else {
            ball.physicsBody!.linearDamping = 0.0
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is GameOver.Type
    }
    
}

/// <#Description#>
class GameOver: GKState {
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        if previousState is Playing {
            let ball = scene.childNode(withName: NodeName.playerBall.rawValue) as! SKSpriteNode
            scene.removeChildren(in: [ball])
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is WaitingForTap.Type
    }
    
}



// MARK: -

/// <#Description#>
class Ball: SKSpriteNode {
    init(from name: String) {
        let imageTexture = SKTexture(imageNamed: name)
        super.init(texture: imageTexture, color: UIColor.clear, size: imageTexture.size())
        self.physicsBody = SKPhysicsBody(texture: imageTexture, size: imageTexture.size())
        self.physicsBody?.usesPreciseCollisionDetection = true
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.friction = 0
        self.physicsBody?.restitution = 1
        self.physicsBody?.linearDamping = 0
        self.physicsBody?.allowsRotation = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


/// <#Description#>
class Paddle: SKSpriteNode {
    init(from name: String) {
        let paddleCategoryName = name
        let imageTexture = SKTexture(imageNamed: paddleCategoryName)
        super.init(texture: imageTexture, color: UIColor.clear, size: imageTexture.size())
        self.physicsBody = SKPhysicsBody(texture: imageTexture, size: imageTexture.size())
        self.physicsBody?.isDynamic = false
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.usesPreciseCollisionDetection = true
        self.physicsBody?.friction = 0.1
        self.physicsBody?.restitution = 1
        self.physicsBody?.linearDamping = 0
        self.physicsBody?.allowsRotation = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


/// <#Description#>
class Brick: SKSpriteNode {
    init(from name: String) {
        let imageTexture = SKTexture(imageNamed: name)
        super.init(texture: imageTexture, color: UIColor.clear, size: imageTexture.size())
        self.physicsBody = SKPhysicsBody(texture: imageTexture, size: imageTexture.size())
        self.physicsBody?.isDynamic = false
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.usesPreciseCollisionDetection = true
        self.physicsBody?.friction = 0
        self.physicsBody?.restitution = 1
        self.physicsBody?.linearDamping = 0
        self.physicsBody?.allowsRotation = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



