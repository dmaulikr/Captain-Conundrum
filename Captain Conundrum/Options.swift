//
//  Options.swift
//  Captain Conundrum
//
//  Created by Basanta Chaudhuri on 7/24/17.
//  Copyright © 2017 Abhishek Chaudhuri. All rights reserved.
//

import SpriteKit

class Options: SKScene {
    var buttonControls: MSButtonNode!
    var buttonCredits: MSButtonNode!
    var buttonCustomize: MSButtonNode!
    var leaderboards: MSButtonNode!
    var achievements: MSButtonNode!
    var buttonBack: MSButtonNode!
    var musicOn: MSButtonNode!
    var musicOff: MSButtonNode!
    var messageTime: CFTimeInterval = 0
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 // 60 FPS
    var comingSoon: SKLabelNode! // Placeholder until features are implemented
    let soundSelect = SKAction.playSoundFileNamed("click1.caf", waitForCompletion: false)
    let soundExit = SKAction.playSoundFileNamed("switch34.caf", waitForCompletion: false)
    
    override func didMove(to view: SKView) {
        buttonControls = childNode(withName: "buttonControls") as! MSButtonNode
        buttonCredits = childNode(withName: "buttonCredits") as! MSButtonNode
        buttonCustomize = childNode(withName: "buttonCustomize") as! MSButtonNode
        leaderboards = childNode(withName: "leaderboards") as! MSButtonNode
        achievements = childNode(withName: "achievements") as! MSButtonNode
        buttonBack = childNode(withName: "buttonBack") as! MSButtonNode
        musicOn = childNode(withName: "musicOn") as! MSButtonNode
        musicOff = childNode(withName: "musicOff") as! MSButtonNode
        comingSoon = childNode(withName: "comingSoon") as! SKLabelNode
        
        buttonControls.selectedHandler = { [unowned self] in
            self.run(self.soundSelect)
            self.comingSoon.isHidden = false
        }
        
        buttonCredits.selectedHandler = { [unowned self] in
            self.run(self.soundSelect)
            self.comingSoon.isHidden = false
        }
        
        buttonCustomize.selectedHandler = { [unowned self] in
            self.run(self.soundSelect)
            self.comingSoon.isHidden = false
        }
        
        leaderboards.selectedHandler = { [unowned self] in
            self.run(self.soundSelect)
            self.comingSoon.isHidden = false
        }
        
        achievements.selectedHandler = { [unowned self] in
            self.run(self.soundSelect)
            self.comingSoon.isHidden = false
        }
        
        buttonBack.selectedHandler = { [unowned self] in
            self.run(self.soundExit)
            self.loadMainMenu()
        }
        
        musicOn.selectedHandler = { [unowned self] in
            self.run(self.soundSelect)
            GameViewController.backgroundMusic.stop()
            self.musicOff.isHidden = false
        }
        
        musicOff.selectedHandler = { [unowned self] in
            GameViewController.backgroundMusic.play()
            self.musicOn.isHidden = false
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
        if GameViewController.backgroundMusic.isPlaying {
            musicOff.isHidden = true
        } else {
            musicOn.isHidden = true
        }
        
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
