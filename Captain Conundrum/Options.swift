//
//  Options.swift
//  Captain Conundrum
//
//  Created by Basanta Chaudhuri on 7/24/17.
//  Copyright © 2017 Abhishek Chaudhuri. All rights reserved.
//

import SpriteKit
import CoreMotion
import AVFoundation

class Options: SKScene, SKPhysicsContactDelegate {
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
    var soundEffects: [String: (file: String, track: AVAudioPlayer?)] = [
        "select": ("click1", nil),
        "exit": ("switch34", nil)
    ]
    
    var screenControls: SKSpriteNode!
    var buttonSlow: MSButtonNode!
    var buttonMedium: MSButtonNode!
    var buttonFast: MSButtonNode!
    var player: SKSpriteNode!
    let thrusters = SKEmitterNode(fileNamed: "Fire")!
    var motionManager: CMMotionManager!
    var controlBoundary: SKSpriteNode!
    var currentControl: SKSpriteNode!
    var exitControls: MSButtonNode!
    var screenCredits: SKSpriteNode!
    var exitCredits: MSButtonNode!
    
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
        
        screenControls = childNode(withName: "screenControls") as! SKSpriteNode
        buttonSlow = screenControls.childNode(withName: "buttonSlow") as! MSButtonNode
        buttonMedium = screenControls.childNode(withName: "buttonMedium") as! MSButtonNode
        buttonFast = screenControls.childNode(withName: "buttonFast") as! MSButtonNode
        player = screenControls.childNode(withName: "player") as! SKSpriteNode
        controlBoundary = screenControls.childNode(withName: "controlBoundary") as! SKSpriteNode
        currentControl = screenControls.childNode(withName: "currentControl") as! SKSpriteNode
        exitControls = screenControls.childNode(withName: "exitControls") as! MSButtonNode
        
        screenCredits = childNode(withName: "screenCredits") as! SKSpriteNode
        exitCredits = screenCredits.childNode(withName: "exitCredits") as! MSButtonNode
        
        for (key: sound, value: (file: file, track: _)) in soundEffects {
            // Get sound effects ready
            let soundFilePath = Bundle.main.path(forResource: file, ofType: "caf")!
            let soundFileURL = URL(fileURLWithPath: soundFilePath)
            
            do {
                let player = try AVAudioPlayer(contentsOf: soundFileURL)
                soundEffects[sound]?.track = player // Parameters are immutable
                soundEffects[sound]?.track?.numberOfLoops = 0 // No loop
            } catch {
                print("Music can't be played.")
            }
        }
        
        buttonControls.selectedHandler = { [unowned self] in
            self.soundEffects["select"]?.track?.prepareToPlay()
            self.soundEffects["select"]?.track?.play()
            self.screenControls.position.x = 0
        }
        
        buttonSlow.selectedHandler = { [unowned self] in
            self.soundEffects["select"]?.track?.prepareToPlay()
            self.soundEffects["select"]?.track?.play()
            self.currentControl.position.y = 140
        }
        
        buttonMedium.selectedHandler = { [unowned self] in
            self.soundEffects["select"]?.track?.prepareToPlay()
            self.soundEffects["select"]?.track?.play()
            self.currentControl.position.y = 75
        }
        
        buttonFast.selectedHandler = { [unowned self] in
            self.soundEffects["select"]?.track?.prepareToPlay()
            self.soundEffects["select"]?.track?.play()
            self.currentControl.position.y = 10
        }
        
        exitControls.selectedHandler = { [unowned self] in
            self.soundEffects["exit"]?.track?.prepareToPlay()
            self.soundEffects["exit"]?.track?.play()
            self.screenControls.position.x = 350
        }
        
        buttonCredits.selectedHandler = { [unowned self] in
            self.soundEffects["select"]?.track?.prepareToPlay()
            self.soundEffects["select"]?.track?.play()
            self.screenCredits.position.x = 0
        }
        
        exitCredits.selectedHandler = { [unowned self] in
            self.soundEffects["exit"]?.track?.prepareToPlay()
            self.soundEffects["exit"]?.track?.play()
            self.screenCredits.position.x = -350
        }
        
        buttonCustomize.selectedHandler = { [unowned self] in
            self.soundEffects["select"]?.track?.prepareToPlay()
            self.soundEffects["select"]?.track?.play()
            self.comingSoon.isHidden = false
        }
        
        leaderboards.selectedHandler = { [unowned self] in
            self.soundEffects["select"]?.track?.prepareToPlay()
            self.soundEffects["select"]?.track?.play()
            self.comingSoon.isHidden = false
        }
        
        achievements.selectedHandler = { [unowned self] in
            self.soundEffects["select"]?.track?.prepareToPlay()
            self.soundEffects["select"]?.track?.play()
            self.comingSoon.isHidden = false
        }
        
        buttonBack.selectedHandler = { [unowned self] in
            self.soundEffects["exit"]?.track?.prepareToPlay()
            self.soundEffects["exit"]?.track?.play()
            self.loadMainMenu()
        }
        
        musicOn.selectedHandler = { [unowned self] in
            self.soundEffects["select"]?.track?.prepareToPlay()
            self.soundEffects["select"]?.track?.play()
            GameViewController.backgroundMusic.stop()
            self.musicOff.isHidden = false
        }
        
        musicOff.selectedHandler = { [unowned self] in
            GameViewController.backgroundMusic.play()
            self.musicOn.isHidden = false
        }
        
        physicsWorld.contactDelegate = self
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        thrusters.position = CGPoint(x: player.position.x, y: player.position.y - 45)
        thrusters.zPosition = 2
        screenControls.addChild(thrusters)
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
        
        guard let motion = motionManager.accelerometerData else {
            return // Accelerometer isn't ready until the next frame
        }
        player.position.x += CGFloat(Double(motion.acceleration.x) * 15)
        thrusters.position = CGPoint(x: player.position.x, y: player.position.y - 45) // Fire moves alongside player
    }
}
