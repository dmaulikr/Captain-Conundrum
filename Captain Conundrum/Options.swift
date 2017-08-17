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
import GameKit // For Game Center

class Options: SKScene, SKPhysicsContactDelegate, GKGameCenterControllerDelegate {
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
    let soundQueue = OperationQueue()
    var soundEffects: [String: (file: String, track: AVAudioPlayer?)] = [
        "select": ("click1", nil),
        "exit": ("switch34", nil)
    ]
    
    var screenControls: SKSpriteNode!
    static var motionConstant = UserDefaults().double(forKey: "motionConstant") {
        didSet {
            if motionConstant == 0 {
                UserDefaults().set(15, forKey: "motionConstant") // Default value
                motionConstant = UserDefaults().double(forKey: "motionConstant")
            }
        }
    }
    var buttonLow: MSButtonNode!
    var buttonMedium: MSButtonNode!
    var buttonHigh: MSButtonNode!
    var player: SKSpriteNode!
    let thrusters = SKEmitterNode(fileNamed: "Fire")!
    var motionManager: CMMotionManager!
    var controlBoundary: SKSpriteNode!
    var currentControl: SKSpriteNode!
    var exitControls: MSButtonNode!
    
    var screenCredits: SKSpriteNode!
    var exitCredits: MSButtonNode!
    
    var screenCustomize: SKSpriteNode!
    static var playerTexture: SKTexture!
    var design1: MSButtonNode!
    var design2: MSButtonNode!
    var design3: MSButtonNode!
    var colorBlue: MSButtonNode!
    var colorGreen: MSButtonNode!
    var colorOrange: MSButtonNode!
    var colorRed: MSButtonNode!
    var outlineShip: SKSpriteNode!
    var outlineColor: SKSpriteNode!
    var exitCustomize: MSButtonNode!
    
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
        buttonLow = screenControls.childNode(withName: "buttonLow") as! MSButtonNode
        buttonMedium = screenControls.childNode(withName: "buttonMedium") as! MSButtonNode
        buttonHigh = screenControls.childNode(withName: "buttonHigh") as! MSButtonNode
        player = screenControls.childNode(withName: "player") as! SKSpriteNode
        controlBoundary = screenControls.childNode(withName: "controlBoundary") as! SKSpriteNode
        currentControl = screenControls.childNode(withName: "currentControl") as! SKSpriteNode
        exitControls = screenControls.childNode(withName: "exitControls") as! MSButtonNode
        
        screenCredits = childNode(withName: "screenCredits") as! SKSpriteNode
        exitCredits = screenCredits.childNode(withName: "exitCredits") as! MSButtonNode
        
        screenCustomize = childNode(withName: "screenCustomize") as! SKSpriteNode
        design1 = screenCustomize.childNode(withName: "design1") as! MSButtonNode
        design2 = screenCustomize.childNode(withName: "design2") as! MSButtonNode
        design3 = screenCustomize.childNode(withName: "design3") as! MSButtonNode
        colorBlue = screenCustomize.childNode(withName: "colorBlue") as! MSButtonNode
        colorGreen = screenCustomize.childNode(withName: "colorGreen") as! MSButtonNode
        colorOrange = screenCustomize.childNode(withName: "colorOrange") as! MSButtonNode
        colorRed = screenCustomize.childNode(withName: "colorRed") as! MSButtonNode
        outlineShip = screenCustomize.childNode(withName: "outlineShip") as! SKSpriteNode
        outlineColor = screenCustomize.childNode(withName: "outlineColor") as! SKSpriteNode
        exitCustomize = screenCustomize.childNode(withName: "exitCustomize") as! MSButtonNode
        
        // Position of currentControl
        switch UserDefaults().double(forKey: "motionConstant") {
            case 10:
                currentControl.position.y = 140
            case 20:
                currentControl.position.y = 10
            default:
                currentControl.position.y = 75
        }
        
        // Position of outlineShip
        switch UserDefaults().integer(forKey: "shipDesign") {
            case 1...4:
                outlineShip.position = design1.position
            case 5...8:
                outlineShip.position = design2.position
            default:
                outlineShip.position = design3.position
        }
        
        // Position of outlineColor
        switch UserDefaults().integer(forKey: "shipDesign") {
            case 1,5,9:
                outlineColor.position = colorBlue.position
                self.design1.texture = SKTexture(imageNamed: "playerShip1_blue")
                self.design2.texture = SKTexture(imageNamed: "playerShip2_blue")
                self.design3.texture = SKTexture(imageNamed: "playerShip3_blue")
            case 3,7,10:
                outlineColor.position = colorOrange.position
                self.design1.texture = SKTexture(imageNamed: "playerShip1_orange")
                self.design2.texture = SKTexture(imageNamed: "playerShip2_orange")
                self.design3.texture = SKTexture(imageNamed: "playerShip3_orange")
            case 4,8,11:
                outlineColor.position = colorRed.position
                self.design1.texture = SKTexture(imageNamed: "playerShip1_red")
                self.design2.texture = SKTexture(imageNamed: "playerShip2_red")
                self.design3.texture = SKTexture(imageNamed: "playerShip3_red")
            default:
                outlineColor.position = colorGreen.position
                self.design1.texture = SKTexture(imageNamed: "playerShip1_green")
                self.design2.texture = SKTexture(imageNamed: "playerShip2_green")
                self.design3.texture = SKTexture(imageNamed: "playerShip3_green")
        }
        
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
        
        soundQueue.qualityOfService = QualityOfService.background
        
        // Controls
        buttonControls.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            self.screenControls.position.x = 0
        }
        
        buttonLow.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            self.currentControl.position.y = 140
            UserDefaults().set(10, forKey: "motionConstant")
        }
        
        buttonMedium.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            self.currentControl.position.y = 75
            UserDefaults().set(15, forKey: "motionConstant")
        }
        
        buttonHigh.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            self.currentControl.position.y = 10
            UserDefaults().set(20, forKey: "motionConstant")
        }
        
        exitControls.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["exit"]?.track?.prepareToPlay()
                self.soundEffects["exit"]?.track?.play()
            }
            self.screenControls.position.x = 350
        }
        
        // Credits
        buttonCredits.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            self.screenCredits.position.x = 0
        }
        
        exitCredits.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["exit"]?.track?.prepareToPlay()
                self.soundEffects["exit"]?.track?.play()
            }
            self.screenCredits.position.x = -350
        }
        
        // Customize
        buttonCustomize.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            self.screenCustomize.position.y = 0
        }
        
        design1.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            self.outlineShip.position = self.design1.position
        }
        
        design2.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            self.outlineShip.position = self.design2.position
        }
        
        design3.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            self.outlineShip.position = self.design3.position
        }
        
        colorBlue.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            self.outlineColor.position = self.colorBlue.position
            // Ships above reflect the color chosen
            self.design1.texture = SKTexture(imageNamed: "playerShip1_blue")
            self.design2.texture = SKTexture(imageNamed: "playerShip2_blue")
            self.design3.texture = SKTexture(imageNamed: "playerShip3_blue")
        }
        
        colorGreen.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            self.outlineColor.position = self.colorGreen.position
            self.design1.texture = SKTexture(imageNamed: "playerShip1_green")
            self.design2.texture = SKTexture(imageNamed: "playerShip2_green")
            self.design3.texture = SKTexture(imageNamed: "playerShip3_green")
        }
        
        colorOrange.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            self.outlineColor.position = self.colorOrange.position
            self.design1.texture = SKTexture(imageNamed: "playerShip1_orange")
            self.design2.texture = SKTexture(imageNamed: "playerShip2_orange")
            self.design3.texture = SKTexture(imageNamed: "playerShip3_orange")
        }
        
        colorRed.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            self.outlineColor.position = self.colorRed.position
            self.design1.texture = SKTexture(imageNamed: "playerShip1_red")
            self.design2.texture = SKTexture(imageNamed: "playerShip2_red")
            self.design3.texture = SKTexture(imageNamed: "playerShip3_red")
        }
        
        exitCustomize.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["exit"]?.track?.prepareToPlay()
                self.soundEffects["exit"]?.track?.play()
            }
            self.screenCustomize.position.y = -600
        }
        
        // Other
        leaderboards.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            // MARK: - OPEN GAME CENTER LEADERBOARD
            // GameViewController().checkGCLeaderboard()
            let gcVC = GKGameCenterViewController()
            gcVC.gameCenterDelegate = self
            gcVC.viewState = .leaderboards
            // User will see all leaderboards (change gcVC.leaderboardIdentifier for specific one)
            self.view?.window?.rootViewController?.present(gcVC, animated: true, completion: nil)
        }
        
        achievements.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            self.comingSoon.isHidden = false
        }
        
        buttonBack.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["exit"]?.track?.prepareToPlay()
                self.soundEffects["exit"]?.track?.play()
            }
            self.loadMainMenu()
        }
        
        musicOn.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
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
        let fade = SKTransition.fade(withDuration: 1)
        
        skView.presentScene(scene, transition: fade)
    }
    
    static func setMotionConstant() -> Double {
        // Called every time motion controls are needed
        return UserDefaults().double(forKey: "motionConstant")
    }
    
    static func setPlayerDesign() -> SKTexture {
        // Called every time the player loads
        let shipDesign = UserDefaults().integer(forKey: "shipDesign")
        // Database of possible ship designs
        switch shipDesign {
            case 1:
                Options.playerTexture = SKTexture(imageNamed: "playerShip1_blue")
            case 2:
                Options.playerTexture = SKTexture(imageNamed: "playerShip1_green")
            case 3:
                Options.playerTexture = SKTexture(imageNamed: "playerShip1_orange")
            case 4:
                Options.playerTexture = SKTexture(imageNamed: "playerShip1_red")
            case 5:
                Options.playerTexture = SKTexture(imageNamed: "playerShip2_blue")
            case 6:
                Options.playerTexture = SKTexture(imageNamed: "playerShip2_green")
            case 7:
                Options.playerTexture = SKTexture(imageNamed: "playerShip2_orange")
            case 8:
                Options.playerTexture = SKTexture(imageNamed: "playerShip2_red")
            case 9:
                Options.playerTexture = SKTexture(imageNamed: "playerShip3_blue")
            case 10:
                Options.playerTexture = SKTexture(imageNamed: "playerShip3_orange")
            case 11:
                Options.playerTexture = SKTexture(imageNamed: "playerShip3_red")
            default:
                Options.playerTexture = SKTexture(imageNamed: "playerShip3_green")
        }
        
        return Options.playerTexture
    }
    
    func playerDesign() {
        // Adjusts look of spaceship based on selection in customization
        switch outlineShip.position {
            case design1.position:
                switch outlineColor.position {
                    case colorBlue.position:
                        UserDefaults().set(1, forKey: "shipDesign")
                    case colorGreen.position:
                        UserDefaults().set(2, forKey: "shipDesign")
                    case colorOrange.position:
                        UserDefaults().set(3, forKey: "shipDesign")
                    default:
                        UserDefaults().set(4, forKey: "shipDesign")
                }
            case design2.position:
                switch outlineColor.position {
                    case colorBlue.position:
                        UserDefaults().set(5, forKey: "shipDesign")
                    case colorGreen.position:
                        UserDefaults().set(6, forKey: "shipDesign")
                    case colorOrange.position:
                        UserDefaults().set(7, forKey: "shipDesign")
                    default:
                        UserDefaults().set(8, forKey: "shipDesign")
                }
            default:
                switch outlineColor.position {
                    case colorBlue.position:
                        UserDefaults().set(9, forKey: "shipDesign")
                    case colorOrange.position:
                        UserDefaults().set(10, forKey: "shipDesign")
                    case colorRed.position:
                        UserDefaults().set(11, forKey: "shipDesign")
                    default:
                        UserDefaults().set(0, forKey: "shipDesign") // Default design
                }
        }
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
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
        
        Options.motionConstant = UserDefaults().double(forKey: "motionConstant") // Update motion within options
        
        guard let motion = motionManager.accelerometerData else {
            return // Accelerometer isn't ready until the next frame
        }
        
        player.position.x += CGFloat(Double(motion.acceleration.x) * Options.motionConstant)
        thrusters.position = CGPoint(x: player.position.x, y: player.position.y - 45) // Fire moves alongside player
        
        playerDesign()
        player.texture = Options.setPlayerDesign() // Update sprite within options
    }
}
