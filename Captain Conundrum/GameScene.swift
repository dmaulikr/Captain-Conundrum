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
    var player: SKSpriteNode!
    var buttonPause: MSButtonNode!
    var boxPause: SKNode!
    var buttonContinue: MSButtonNode!
    var buttonQuit: MSButtonNode!
    var scrollLayer: SKNode!
    var fixedDelta: CFTimeInterval = 1.0 / 60.0 // 60 FPS
    var scrollSpeed: CGFloat = 100
    var motionManager: CMMotionManager!
    var gameState: GameState = .active
    
    override func didMove(to view: SKView) {
        // Called immediately after scene is loaded into view
        player = childNode(withName: "player") as! SKSpriteNode
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
        }
        
        buttonContinue.selectedHandler = {
            self.gameState = .active
            self.boxPause.isHidden = true
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Called once a touch is detected
    }
    
    /*override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
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
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Called when two bodies make contact
    }
}