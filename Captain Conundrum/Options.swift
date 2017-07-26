//
//  Options.swift
//  Captain Conundrum
//
//  Created by Basanta Chaudhuri on 7/24/17.
//  Copyright © 2017 Abhishek Chaudhuri. All rights reserved.
//

import SpriteKit

class Options: SKScene {
    var leaderboards: MSButtonNode!
    var achievements: MSButtonNode!
    var buttonBack: MSButtonNode!
    var musicToggle: MSButtonNode!
    var messageTime: CFTimeInterval = 0
    var fixedDelta: CFTimeInterval = 1.0 / 60.0 // 60 FPS
    var comingSoon: SKLabelNode! // Placeholder until features are implemented
    
    override func didMove(to view: SKView) {
        leaderboards = childNode(withName: "leaderboards") as! MSButtonNode
        achievements = childNode(withName: "achievements") as! MSButtonNode
        buttonBack = childNode(withName: "buttonBack") as! MSButtonNode
        musicToggle = childNode(withName: "musicToggle") as! MSButtonNode
        comingSoon = childNode(withName: "comingSoon") as! SKLabelNode
        
        leaderboards.selectedHandler = {
            self.comingSoon.isHidden = false
        }
        
        achievements.selectedHandler = {
            self.comingSoon.isHidden = false
        }
        
        buttonBack.selectedHandler = {
            self.loadMainMenu()
        }
        
        musicToggle.selectedHandler = {
            self.comingSoon.isHidden = false
        }
    }
    
    func loadMainMenu() {
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
    
    override func update(_ currentTime: TimeInterval) {
        if comingSoon.isHidden == false {
            messageTime += fixedDelta
        }
        
        // After 1 second, the coming soon message disappears
        if messageTime >= 1.0 {
            comingSoon.isHidden = true // Returns to default state
            messageTime = 0 // Reset timer for each cycle
        }
    }
}
