//
//  MainMenu.swift
//  Captain Conundrum
//
//  Created by Basanta Chaudhuri on 7/24/17.
//  Copyright © 2017 Abhishek Chaudhuri. All rights reserved.
//

import SpriteKit

class MainMenu: SKScene, SKPhysicsContactDelegate {
    var player: MSButtonNode!
    var blast: SKSpriteNode!
    var title: SKSpriteNode!
    var buttonStart: MSButtonNode!
    var buttonOptions: MSButtonNode!
    var scrollLayer: SKNode!
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 // 60 FPS
    let scrollSpeed: CGFloat = 100
    let soundSelect = SKAction.playSoundFileNamed("click1.caf", waitForCompletion: false)
    let soundAttack = SKAction.playSoundFileNamed("laser5.caf", waitForCompletion: false)
    let soundExplosion = SKAction.playSoundFileNamed("cc0_explosion_large_gun_powder.caf", waitForCompletion: false)
    
    override func didMove(to view: SKView) {
        player = childNode(withName: "player") as! MSButtonNode
        blast = childNode(withName: "blast") as! SKSpriteNode
        title = childNode(withName: "title") as! SKSpriteNode
        buttonStart = childNode(withName: "buttonStart") as! MSButtonNode
        buttonOptions = childNode(withName: "buttonOptions") as! MSButtonNode
        scrollLayer = childNode(withName: "scrollLayer")
        
        player.selectedHandler = { [unowned self] in // Prevents memory leaks from MSButtonNode
            self.run(self.soundAttack)
            self.blast.physicsBody?.velocity = CGVector(dx: 0, dy: 500) // Secret button!
            
            if self.blast.position.y >= 325 {
                self.blast.position.y = 0 // Replace attack when offscreen
            }
        }
        
        buttonStart.selectedHandler = { [unowned self] in
            self.run(self.soundSelect)
            self.loadGame()
        }
        
        buttonOptions.selectedHandler = { [unowned self] in
            self.run(self.soundSelect)
            self.loadOptions()
        }
        
        physicsWorld.contactDelegate = self
        let thrusters = SKEmitterNode(fileNamed: "Fire")!
        thrusters.position.y = -45
        addChild(thrusters)
    }
    
    func loadGame() {
        guard let skView = self.view as SKView! else {
            print("Cound not get SKview")
            return
        }
        
        guard let scene = GameScene(fileNamed: "GameScene") else {
            print("Could not load GameScene, check the name is spelled correctly")
            return
        }
        
        scene.scaleMode = .aspectFit
        skView.showsFPS = true
        let fade = SKTransition.fade(withDuration: 1)
        
        skView.presentScene(scene, transition: fade)
    }
    
    func loadOptions() {
        guard let skView = self.view as SKView! else {
            print("Cound not get SKview")
            return
        }
        
        guard let scene = GameScene(fileNamed: "Options") else {
            print("Could not load Options, check the name is spelled correctly")
            return
        }
        
        scene.scaleMode = .aspectFit
        skView.showsFPS = true
        let fade = SKTransition.fade(withDuration: 1)
        
        skView.presentScene(scene, transition: fade)
    }
    
    override func update(_ currentTime: TimeInterval) {
        scrollLayer.position.y -= scrollSpeed * CGFloat(fixedDelta) // Moves scrollLayer along with child stars
        
        for star in scrollLayer.children as! [SKSpriteNode] {
            // Moves stars back to original position to give illusion of endless scrolling
            let starPosition = scrollLayer.convert(star.position, to: self)
            
            if starPosition.y <= -305 { // Offscreen
                let newPosition = CGPoint(x: starPosition.x, y: (self.size.height / 2) + star.size.height)
                star.position = self.convert(newPosition, to: scrollLayer)
            }
            
            if title.position.y <= -310 {
                title.removeFromParent()
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        
        guard let nodeA = contactA.node else { return }
        guard let nodeB = contactB.node else { return }
        
        if nodeA.name == "blast" && nodeB.name == "title" || nodeA.name == "title" && nodeB.name == "blast" {
            // Title will spin out of control!
            run(soundExplosion)
            if nodeA.name == "blast" {
                blast = nodeA as! SKSpriteNode
                blast.position.y = 0
                title = nodeB as! SKSpriteNode
                title.physicsBody?.angularVelocity = 50
                title.physicsBody?.velocity = CGVector(dx: 0, dy: -400)
            } else {
                blast = nodeB as! SKSpriteNode
                blast.position.y = 0
                title = nodeA as! SKSpriteNode
                title.physicsBody?.angularVelocity = 50
                title.physicsBody?.velocity = CGVector(dx: 0, dy: -400)
            }
        }
    }
}
