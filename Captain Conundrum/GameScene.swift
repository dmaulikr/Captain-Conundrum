//
//  GameScene.swift
//  Captain Conundrum
//
//  Created by Basanta Chaudhuri on 7/24/17.
//  Copyright © 2017 Abhishek Chaudhuri. All rights reserved.
//

import SpriteKit
import CoreMotion

enum GameState {
    case active, paused, gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    // Main variables and buttons
    var player: SKSpriteNode!
    var meteor: SKSpriteNode!
    var buttonPause: MSButtonNode!
    var boxPause: SKNode!
    var buttonContinue: MSButtonNode!
    var buttonQuit: MSButtonNode!
    
    // Scrolling
    var scrollLayer: SKNode!
    var fixedDelta: CFTimeInterval = 1.0 / 60.0 // 60 FPS
    var scrollSpeed: CGFloat = 100
    
    // Other
    var motionManager: CMMotionManager!
    var meteorsHit = 0 // Keeps track of initial meteor herd
    var messageTime: CFTimeInterval = 0 // In seconds
    var isTouching = false
    var touchTime: CFTimeInterval = 0
    var gameState: GameState = .active
    
    var attack: SKSpriteNode = {
        let blast = SKSpriteNode()
        blast.name = "attack"
        blast.size.width = 15
        blast.size.height = 40
        blast.color = .orange
        blast.zPosition = 1
        blast.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: blast.size.width, height: blast.size.height))
        blast.physicsBody?.pinned = false
        blast.physicsBody?.affectedByGravity = false
        blast.physicsBody?.categoryBitMask = 4
        blast.physicsBody?.collisionBitMask = 4
        blast.physicsBody?.contactTestBitMask = 8
        return blast
    } ()
    
    var startMessage: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Britannic Bold")
        label.fontSize = 96
        label.position = CGPoint(x: 0, y: 0)
        label.zPosition = 1
        label.text = "Start"
        return label
    } ()
    
    override func didMove(to view: SKView) {
        // Called immediately after scene is loaded into view
        player = childNode(withName: "player") as! SKSpriteNode
        meteor = childNode(withName: "meteor") as! SKSpriteNode
        buttonPause = childNode(withName: "buttonPause") as! MSButtonNode
        boxPause = childNode(withName: "boxPause")
        buttonContinue = boxPause.childNode(withName: "buttonContinue") as! MSButtonNode
        buttonQuit = boxPause.childNode(withName: "buttonQuit") as! MSButtonNode
        scrollLayer = childNode(withName: "scrollLayer")
        
        if gameState == .active {
            self.boxPause.isHidden = true
        }
        
        buttonPause.selectedHandler = {
            self.gameState = .paused
            self.boxPause.isHidden = false
            // If the player pauses while firing, the shot stops
            if let blast = self.attack.physicsBody {
                blast.velocity.dy = 0
            }
        }
        
        buttonContinue.selectedHandler = {
            self.gameState = .active
            self.boxPause.isHidden = true
            if let blast = self.attack.physicsBody {
                blast.velocity.dy = 500
            }
        }
        
        buttonQuit.selectedHandler = {
            guard let skView = self.view as SKView! else {
                print("Cound not get SKview")
                return
            }
            
            guard let scene = GameScene(fileNamed: "MainMenu") else {
                print("Could not load MainMenu, check the name is spelled correctly")
                return
            }
            
            scene.scaleMode = .aspectFit
            skView.showsFPS = true
            let fade = SKTransition.fade(withDuration: 1)
            
            skView.presentScene(scene, transition: fade)
        }
        
        physicsWorld.contactDelegate = self
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
    }
    
    /*func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }*/
    
    func shoot() {
        // Copies allow for multiple attacks on screen
        let multiAttack = attack.copy() as! SKSpriteNode
        addChild(multiAttack)
        multiAttack.position = player.position
        multiAttack.physicsBody?.velocity = CGVector(dx: 0, dy: 500)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Called once a touch is detected
        if gameState != .active { return }
        
        isTouching = true
        shoot()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Called when finger is lifted off the phone
        if gameState != .active { return }
        
        isTouching = false
    }
    
    /*override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }*/
    
    func scrollWorld() {
        scrollLayer.position.y -= scrollSpeed * CGFloat(fixedDelta) // Moves scrollLayer along with child stars
        
        for star in scrollLayer.children as! [SKSpriteNode] {
            // Moves stars back to original position to give illusion of endless scrolling
            let starPosition = scrollLayer.convert(star.position, to: self)
            
            if starPosition.y <= -305 { // Offscreen
                let newPosition = CGPoint(x: starPosition.x, y: (self.size.height / 2) + star.size.height)
                star.position = self.convert(newPosition, to: scrollLayer)
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if gameState != .active { return }
        
        guard let motion = motionManager.accelerometerData else {
            return // Accelerometer isn't ready until the next frame
        }
        player.position.x += CGFloat(Double((motion.acceleration.x)) * 15)
        
        scrollWorld()
        
        if attack.position.y >= 325 {
            attack.removeFromParent() // Remove attack when offscreen
        }
        
        // After 1 second, Start disappears
        if messageTime >= 1.0 {
            startMessage.removeFromParent()
        }
        
        if meteorsHit == 3 {
            messageTime += fixedDelta
        } else if meteorsHit > 3 {
            messageTime = 0 // Reset time for any future messages
        }
        
        if isTouching {
            touchTime += fixedDelta
            
            if touchTime >= 0.5 { // Auto-fire every 0.5 seconds
                shoot()
                touchTime = 0
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Called when two bodies make contact
        if gameState != .active { return }
        
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        if nodeA.name == "attack" && nodeB.name == "meteor" || nodeA.name == "meteor" && nodeB.name == "attack" {
            nodeA.removeFromParent()
            nodeB.removeFromParent()
            meteorsHit += 1
            if meteorsHit == 3 {
                addChild(startMessage) // Player has completed tutorial section
            }
        }
    }
}
