//
//  GameScene.swift
//  Captain Conundrum
//
//  Created by Basanta Chaudhuri on 7/24/17.
//  Copyright © 2017 Abhishek Chaudhuri. All rights reserved.
//

import SpriteKit
import CoreMotion
import Foundation
import AVFoundation
import GameKit

enum GameState {
    case active, paused, gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    // Player and enemies
    var player: SKSpriteNode! {
        didSet {
            player.texture = Options.setPlayerDesign()
        }
    }
    var initialMeteor: SKSpriteNode!
    var meteor: SKSpriteNode!
    var satellite: SKSpriteNode!
    var rocket: SKSpriteNode!
    var ufo: SKSpriteNode!
    let thrusters = SKEmitterNode(fileNamed: "Fire")!
    var enemySpeed: [String: Double] = [
        // Info about each enemy
        "meteor": -100,
        "satelliteX": -200, "satelliteY": -200,
        "rocket": -300,
        "ufo+": 150, "ufo-": -150,
        "powerUp": -200
    ]
    
    // Power ups
    var powerupHealth: SKSpriteNode!
    var powerupRapidFire: SKSpriteNode!
    var powerupSpread: SKSpriteNode!
    var powerupInvincible: SKSpriteNode!
    var touchedPower = false
    var hasPower: [String: Bool] = [
        // Determines which power up(s) the player has
        "health": false,
        "rapidFire": false,
        "spread": false,
        "invincible": false
    ]
    
    // Buttons
    var buttonPause: MSButtonNode!
    var boxPause: SKNode!
    var buttonContinue: MSButtonNode!
    var buttonQuit: MSButtonNode! // Pause
    var boxGameOver: SKNode!
    var buttonRetry: MSButtonNode!
    var buttonQuit2: MSButtonNode! // Game Over
    
    // Scrolling
    var scrollLayer: SKNode!
    let fixedDelta: CFTimeInterval = 1.0 / 60.0 // 60 FPS
    let scrollSpeed: CGFloat = 100
    
    // Timers (in seconds)
    var messageTime:     CFTimeInterval = 0 // Start message
    var enemySpawnTimer: CFTimeInterval = 0 // Enemy spawning
    var powerSpawnTimer: CFTimeInterval = 0 // Power up spawning
    var touchTime:       CFTimeInterval = 0 // Holding down touch
    var fadeTime:        CFTimeInterval = 0 // Invulnerable to damage
    var powerTime:       CFTimeInterval = 0 // Power up active
    var otherTouch = DispatchTime.now()
    
    // Music
    let soundQueue = OperationQueue()
    var soundEffects: [String: (file: String, track: AVAudioPlayer?)] = [
        // Stores all music tracks
        "select": ("click1", nil),
        "incoming": ("highDown", nil),
        "exit": ("switch34", nil),
        "attack": ("laser5_trimmed", nil),
        "enemy attack": ("laser7", nil),
        "explosion": ("cc0_explosion_large_gun_powder_trimmed", nil),
        "power up": ("powerUp12", nil)
    ]
    
    // Achievements
    let achievement1000 =      GKAchievement(identifier: "achievement.score.1000")
    let achievement3000 =      GKAchievement(identifier: "achievement.score.3000")
    let achievement_50 =       GKAchievement(identifier: "achievement.score._50")
    let achievementNoPower =   GKAchievement(identifier: "achievement.nopower")
    let achievementAccurate =  GKAchievement(identifier: "achievement.accuracy.100")
    let achievementMeteor =    GKAchievement(identifier: "achievement.onlymeteor")
    let achievementSatellite = GKAchievement(identifier: "achievement.onlysatellite")
    let achievementRocket =    GKAchievement(identifier: "achievement.justrocket")
    let achievementUFO =       GKAchievement(identifier: "achievement.onlyufo")
    
    // Other
    var scoreLabel: SKLabelNode!
    var timeLabel: SKLabelNode!
    var currentMessage: SKLabelNode!
    var healthBorder: SKSpriteNode!
    var healthBar: SKSpriteNode!
    var motionManager: CMMotionManager!
    var joystick: JoystickNode!
    let movementSpeed: CGFloat = 2
    var initialMeteorsHit = 0 // Keeps track of initial meteor herd
    var meteorsHit = 0
    var satellitesHit = 0
    var rocketsHit = 0
    var ufosHit = 0
    var numberOfBlasts = 0
    var blastLimit = 3 // Only 3 lasers allowed on screen at once
    var timeBetweenBlasts = 0.5 // Auto-fire every 0.5 seconds
    var hits: Double = 0
    var misses: Double = 0
    var rocketArray: [SKSpriteNode] = []
    var ufoArray: [SKSpriteNode] = []
    var ufoData: [(action: Int, originalPosition: CGFloat, timer: CFTimeInterval)] = []
    var isTouching = false
    var isInvincible = false
    var gameStart = false
    var gameState: GameState = .active
    
    var score = 0 {
        didSet {
            scoreLabel.text = String(score)
        }
    }
    
    var timeLimit: Int = 10 { // Power ups only last 10 seconds
        didSet {
            timeLabel.text = String(timeLimit)
        }
    }
    
    var attack: SKSpriteNode = {
        let blast = SKSpriteNode(imageNamed: "laserRed02")
        blast.name = "attack"
        blast.zPosition = 1
        blast.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: blast.size.width, height: blast.size.height))
        blast.physicsBody?.allowsRotation = false
        blast.physicsBody?.affectedByGravity = false
        blast.physicsBody?.categoryBitMask = 4
        blast.physicsBody?.collisionBitMask = 0
        blast.physicsBody?.contactTestBitMask = 122 // In contact with all enemies and boundaries
        return blast
    } ()
    
    var ufoAttack: SKSpriteNode = {
        let blast = SKSpriteNode(imageNamed: "laserBlue05")
        blast.name = "ufoAttack"
        blast.zPosition = 1
        blast.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: blast.size.width, height: blast.size.height))
        blast.physicsBody?.allowsRotation = false
        blast.physicsBody?.affectedByGravity = false
        blast.physicsBody?.categoryBitMask = 256
        blast.physicsBody?.collisionBitMask = 0
        blast.physicsBody?.contactTestBitMask = 258 // In contact with player and bottom boundary
        return blast
    } ()
    
    var startMessage: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Britannic Bold")
        label.fontSize = 96
        label.fontColor = .green
        label.position = CGPoint(x: 0, y: 0)
        label.zPosition = 1
        label.text = "Start"
        return label
    } ()
    
    var powerupMessage: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Britannic Bold")
        label.fontSize = 36
        label.fontColor = .green
        label.position = CGPoint(x: 0, y: 180)
        label.zPosition = 2
        return label
    } ()
    
    var highScoreLabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Britannic Bold")
        label.fontSize = 36
        label.fontColor = .cyan
        label.position = CGPoint(x: 0, y: 175)
        label.zPosition = 2
        label.text = "High Score: \(UserDefaults().integer(forKey: "highscore"))"
        return label
    } ()
    
    var lowScoreLabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Britannic Bold")
        label.fontSize = 36
        label.fontColor = .cyan
        label.position = CGPoint(x: 0, y: 175)
        label.zPosition = 2
        label.text = "Low Score: \(UserDefaults().integer(forKey: "lowscore"))"
        return label
    } ()
    
    var newRecordLabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Britannic Bold")
        label.fontSize = 36
        label.fontColor = .green
        label.position = CGPoint(x: 0, y: 125)
        label.zPosition = 2
        label.text = "New Record!"
        return label
    } ()
    
    var hitsMessage: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Brtiannic Bold")
        label.fontSize = 36
        label.fontColor = .cyan
        label.position = CGPoint(x: 0, y: -130)
        label.zPosition = 2
        return label
    } ()
    
    var missMessage: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Britannic Bold")
        label.fontSize = 36
        label.fontColor = .cyan
        label.position = CGPoint(x: 0, y: -180)
        label.zPosition = 2
        return label
    } ()
    
    var ratioMessage: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Britannic Bold")
        label.fontSize = 32
        label.fontColor = .cyan
        label.position = CGPoint(x: 0, y: -230)
        label.zPosition = 2
        return label
    } ()
    
    override func didMove(to view: SKView) {
        // Called immediately after scene is loaded into view
        player = childNode(withName: "player") as! SKSpriteNode
        initialMeteor = childNode(withName: "initialMeteor") as! SKSpriteNode
        meteor = childNode(withName: "meteor") as! SKSpriteNode
        satellite = childNode(withName: "satellite") as! SKSpriteNode
        rocket = childNode(withName: "rocket") as! SKSpriteNode
        ufo = childNode(withName: "ufo") as! SKSpriteNode
        
        powerupHealth = childNode(withName: "powerupHealth") as! SKSpriteNode
        powerupRapidFire = childNode(withName: "powerupRapidFire") as! SKSpriteNode
        powerupSpread = childNode(withName: "powerupSpread") as! SKSpriteNode
        powerupInvincible = childNode(withName: "powerupInvincible") as! SKSpriteNode
        
        buttonPause = childNode(withName: "buttonPause") as! MSButtonNode
        boxPause = childNode(withName: "boxPause")
        buttonContinue = boxPause.childNode(withName: "buttonContinue") as! MSButtonNode
        buttonQuit = boxPause.childNode(withName: "buttonQuit") as! MSButtonNode
        boxGameOver = childNode(withName: "boxGameOver")
        buttonRetry = boxGameOver.childNode(withName: "buttonRetry") as! MSButtonNode
        buttonQuit2 = boxGameOver.childNode(withName: "buttonQuit2") as! MSButtonNode
        
        scrollLayer = childNode(withName: "scrollLayer")
        scoreLabel = childNode(withName: "scoreLabel") as! SKLabelNode
        timeLabel = childNode(withName: "timeLabel") as! SKLabelNode
        healthBorder = childNode(withName: "healthBorder") as! SKSpriteNode
        healthBar = healthBorder.childNode(withName: "healthBar") as! SKSpriteNode
        
        joystick = JoystickNode(radius: 25, backgroundColor: UIColor(red: 75 / 255, green: 75 / 255, blue: 75 / 255, alpha: 0.6), mainColor: UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.9))
        joystick.position = CGPoint(x: -75, y: -225)
        addChild(joystick)
        
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
        
        // Play sounds in a thread instead of in a separate program
        soundQueue.qualityOfService = QualityOfService.background
        
        buttonPause.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            
            if self.gameState == .gameOver { return }
            self.gameState = .paused
            self.boxPause.isHidden = false
        }
        
        buttonContinue.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            
            self.gameState = .active
            self.boxPause.isHidden = true
            self.isPaused = false
        }
        
        buttonQuit.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["exit"]?.track?.prepareToPlay()
                self.soundEffects["exit"]?.track?.play()
            }
            
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
            self.isPaused = false
            
            skView.presentScene(scene, transition: fade)
        }
        
        buttonRetry.selectedHandler = { [unowned self] in
            self.soundQueue.addOperation {
                self.soundEffects["select"]?.track?.prepareToPlay()
                self.soundEffects["select"]?.track?.play()
            }
            
            self.boxGameOver.position.x = -320
            
            guard let skView = self.view as SKView! else {
                print("Could not get SKview")
                return
            }
            
            guard let scene = GameScene(fileNamed: "SpaceScene") else {
                print("Could not load SpaceScene, check the name is spelled correctly")
                return
            }
            
            scene.scaleMode = .aspectFit
            let fade = SKTransition.fade(withDuration: 1)
            
            skView.presentScene(scene, transition: fade)
        }
        
        buttonQuit2.selectedHandler = buttonQuit.selectedHandler
        
        physicsWorld.contactDelegate = self
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        thrusters.position.y = player.position.y - 45
        addChild(thrusters)
    }
    
    func shoot() {
        if numberOfBlasts >= blastLimit { return }
        // Make sure two shots aren't firing within 2 milliseconds of each other
        let firstTouch = otherTouch
        otherTouch = DispatchTime.now()
        if Double(otherTouch.uptimeNanoseconds - firstTouch.uptimeNanoseconds) <= 2000000 { return }
        // Copies allow for multiple attacks on screen
        let multiAttack = attack.copy() as! SKSpriteNode
        self.soundQueue.addOperation {
            self.soundEffects["attack"]?.track?.prepareToPlay()
            self.soundEffects["attack"]?.track?.play()
        }
        
        addChild(multiAttack)
        multiAttack.position = player.position
        multiAttack.physicsBody?.velocity = CGVector(dx: 0, dy: 500)
        numberOfBlasts += 1
        
        // Add more attacks if power ups are enabled
        if blastLimit > 6 {
            let secondAttack = attack.copy() as! SKSpriteNode
            addChild(secondAttack)
            secondAttack.position = player.position
            secondAttack.zRotation = 10
            secondAttack.physicsBody?.velocity = CGVector(dx: -100, dy: 500)
            numberOfBlasts += 1
            
            let thirdAttack = attack.copy() as! SKSpriteNode
            addChild(thirdAttack)
            thirdAttack.position = player.position
            thirdAttack.zRotation = -10
            thirdAttack.physicsBody?.velocity = CGVector(dx: 100, dy: 500)
            numberOfBlasts += 1
        }
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
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Called when an alert interrupts gameplay
        if gameState != .active { return }
        
        isTouching = false
    }
    
    func scrollWorld() {
        // Endlessly create and destroy stars to give illusion of scrolling
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
    
    func spawnEnemy() {
        // Randomly spawns an enemy falling from the top every second
        if enemySpawnTimer < 1 { return }
        
        let enemy = arc4random_uniform(4) // 4 enemies to choose from
        let enemyPosition = CGPoint(x: CGFloat.random(min: -117, max: 117), y: 305)
        self.soundQueue.addOperation {
            self.soundEffects["incoming"]?.track?.prepareToPlay()
            self.soundEffects["incoming"]?.track?.play()
        }
        
        switch enemy {
            case 0:
                let newMeteor = meteor.copy() as! SKSpriteNode
                newMeteor.position = enemyPosition
                newMeteor.physicsBody?.velocity = CGVector(dx: 0, dy: enemySpeed["meteor"]!) // Fall down slowly
                addChild(newMeteor)
            case 1:
                let newSatellite = satellite.copy() as! SKSpriteNode
                newSatellite.position = enemyPosition
                newSatellite.physicsBody?.velocity = CGVector(dx: enemySpeed["satelliteX"]!, dy: enemySpeed["satelliteY"]!) // Move diagonally
                addChild(newSatellite)
            case 2:
                let newRocket = rocket.copy() as! SKSpriteNode
                newRocket.position = enemyPosition
                newRocket.physicsBody?.velocity = CGVector(dx: 0, dy: enemySpeed["rocket"]!) // Fall quickly
                addChild(newRocket)
                rocketArray.append(newRocket) // Rocket collection
            default:
                let newUFO = ufo.copy() as! SKSpriteNode
                newUFO.position = enemyPosition
                newUFO.physicsBody?.velocity = CGVector(dx: enemySpeed["ufo+"]!, dy: enemySpeed["ufo-"]!) // Zigzag
                addChild(newUFO)
                ufoArray.append(newUFO) // UFO collection
                ufoData.append((0, 0, 0))  // UFO behavior
        }
        
        enemySpawnTimer = 0
    }
    
    func spawnPowerUp() {
        // Randomly spawns a power up from the top every 30 seconds
        if powerSpawnTimer < 30 { return }
        
        let powerUp = arc4random_uniform(4) // 4 power ups to choose from
        let powerUpPosition = CGPoint(x: CGFloat.random(min: -117, max: 117), y: 305)
        self.soundQueue.addOperation {
            self.soundEffects["incoming"]?.track?.prepareToPlay()
            self.soundEffects["incoming"]?.track?.play()
        }
        
        switch powerUp {
            case 0:
                let newHealth = powerupHealth.copy() as! SKSpriteNode
                newHealth.position = powerUpPosition
                newHealth.physicsBody?.velocity = CGVector(dx: 0, dy: enemySpeed["powerUp"]!) // Fall down very quickly
                addChild(newHealth)
            case 1:
                let newFire = powerupRapidFire.copy() as! SKSpriteNode
                newFire.position = powerUpPosition
                newFire.physicsBody?.velocity = CGVector(dx: 0, dy: enemySpeed["powerUp"]!)
                addChild(newFire)
            case 2:
                let newSpread = powerupSpread.copy() as! SKSpriteNode
                newSpread.position = powerUpPosition
                newSpread.physicsBody?.velocity = CGVector(dx: 0, dy: enemySpeed["powerUp"]!)
                addChild(newSpread)
            default:
                let newInvincible = powerupInvincible.copy() as! SKSpriteNode
                newInvincible.position = powerUpPosition
                newInvincible.physicsBody?.velocity = CGVector(dx: 0, dy: enemySpeed["powerUp"]!)
                addChild(newInvincible)
        }
        
        powerSpawnTimer = 0
    }
    
    func rocketAI() {
        // Controls the behavior of each rocket
        for rocket in rocketArray {
            let thruster = SKEmitterNode(fileNamed: "Fire")!
            thruster.emissionAngle = 90 // Rocket is facing other way from player
            thruster.position = CGPoint(x: rocket.position.x, y: rocket.position.y + 50)
            addChild(thruster)
            // Thrusters will stay for a split second before leaving
            let wait = SKAction.wait(forDuration: 0.1)
            let removeParticles = SKAction.removeFromParent()
            let seq = SKAction.sequence([wait, removeParticles])
            thruster.run(seq)
        }
    }
    
    func ufoAI() {
        // Controls the behavior of each UFO
        for ufo in ufoArray {
            // Action: 0 = +dx, 1 = -dx
            guard let index = ufoArray.index(of: ufo) else { return }
            ufoData[index].timer += fixedDelta
            
            // Every 2 seconds, the UFO fires
            if ufoData[index].timer >= 2 {
                let multiAttack = ufoAttack.copy() as! SKSpriteNode
                self.soundQueue.addOperation {
                    self.soundEffects["enemy attack"]?.track?.prepareToPlay()
                    self.soundEffects["enemy attack"]?.track?.play()
                }
                
                addChild(multiAttack)
                multiAttack.position = ufo.position
                multiAttack.physicsBody?.velocity = CGVector(dx: 0, dy: -250)
                ufoData[index].timer = 0
            }
            
            // UFO is moving to the side and is about to hit a wall
            if ufoData[index].action == 0 && ufo.position.x >= 125 || ufoData[index].action == 1 && ufo.position.x <= -125 {
                // UFO won't collide with side boundaries
                ufoData[index].originalPosition = ufo.position.y
                ufo.physicsBody?.velocity = CGVector(dx: 0, dy: enemySpeed["ufo-"]!)
                
                if ufoData[index].action == 0 { ufoData[index].action += 1 }
                else { ufoData[index].action -= 1 }
            }
            
            // UFO is moving down and is about to change direction
            if ufoData[index].originalPosition != 0 && ufoData[index].originalPosition - ufo.position.y >= 150 {
                ufoData[index].originalPosition = 0
                
                if ufoData[index].action == 0 {
                    ufo.physicsBody?.velocity = CGVector(dx: enemySpeed["ufo+"]!, dy: 0)
                } else {
                    ufo.physicsBody?.velocity = CGVector(dx: enemySpeed["ufo-"]!, dy: 0)
                }
            }
            
            // Ensures UFO is avoidable when close to player
            if ufo.position.y <= -140 {
                ufo.physicsBody?.velocity = CGVector(dx: 0, dy: enemySpeed["ufo-"]!)
                ufoData[index].action = 2
            }
        }
    }
    
    func powerHealth() {
        // Player restores health (the only power without a timer)
        if healthBar.xScale >= 1.26 {
            healthBar.xScale = 1.8 // Health bar won't extend beyond border
        } else {
            healthBar.xScale += 0.54
        }
        
        // Turn the health bar back to green if health is more than half full
        if healthBar.xScale > 0.9 {
            healthBar.texture = SKTexture(imageNamed: "green_button04")
        }
        
        hasPower["health"] = false
        powerupHealth.position.x = 250
    }
    
    func powerRapidFire() {
        // Player can shoot more lasers at once
        powerupRapidFire.position = CGPoint(x: -120, y: 210)
        powerupRapidFire.physicsBody?.categoryBitMask = 0 // Don't shoot the power up!
        blastLimit = 6
        timeBetweenBlasts = 0.25
        powerTime += fixedDelta
        
        if abs(powerTime - round(powerTime)) <= 0.01 {
            // Time label decreases every second
            timeLimit -= 1
        }
        
        if powerTime >= 10 {
            blastLimit = 3
            timeBetweenBlasts = 0.5
            powerTime = 0
            hasPower["rapidFire"] = false
            timeLabel.isHidden = true
            timeLimit = 10
            powerupRapidFire.position.x = 300
            powerupRapidFire.physicsBody?.categoryBitMask = 512
        }
    }
    
    func powerSpreadShot() {
        // Player can shoot in multiple directions at once
        powerupSpread.position = CGPoint(x: -120, y: 210)
        powerupSpread.physicsBody?.categoryBitMask = 0
        blastLimit = 9
        powerTime += fixedDelta
        
        if abs(powerTime - round(powerTime)) <= 0.01 {
            // Time label decreases every second
            timeLimit -= 1
        }
        
        if powerTime >= 10 {
            blastLimit = 3
            powerTime = 0
            hasPower["spread"] = false
            timeLabel.isHidden = true
            timeLimit = 10
            powerupSpread.position.x = 350
            powerupSpread.physicsBody?.categoryBitMask = 512
        }
    }
    
    func powerInvincible() {
        // Player is invulnerable to damage for 10 seconds
        powerupInvincible.position = CGPoint(x: -120, y: 210)
        powerupInvincible.physicsBody?.categoryBitMask = 0
        player.physicsBody?.contactTestBitMask = 0
        player.alpha = 0.5 // Appear to be invisible
        powerTime += fixedDelta
        
        if abs(powerTime - round(powerTime)) <= 0.01 {
            // Time label decreases every second
            timeLimit -= 1
        }
        
        if powerTime >= 10 {
            player.physicsBody?.contactTestBitMask = 1016
            player.alpha = 1
            powerTime = 0
            hasPower["invincible"] = false
            timeLabel.isHidden = true
            timeLimit = 10
            powerupInvincible.position.x = 400
            powerupInvincible.physicsBody?.categoryBitMask = 512
        }
    }
    
    func checkGCAchievements() {
        // Checks how far the player has fulfilled an achievement
        if score >= 1000 && !achievement1000.isCompleted {
            // Player scored at least 1000 points
            achievement1000.percentComplete = 100.0
            achievement1000.showsCompletionBanner = true // Achievement unlocked
            GKAchievement.report([achievement1000], withCompletionHandler: nil)
        }
        
        if score >= 3000 && !achievement3000.isCompleted {
            // Player scored at least 3000 points
            achievement3000.percentComplete = 100.0
            achievement3000.showsCompletionBanner = true
            GKAchievement.report([achievement3000], withCompletionHandler: nil)
        }
        
        if score <= -50 && !achievement_50.isCompleted {
            // Player scored at most -50 points
            achievement_50.percentComplete = 100.0
            achievement_50.showsCompletionBanner = true
            GKAchievement.report([achievement_50], withCompletionHandler: nil)
        }
        
        if score >= 3000 && !touchedPower && !achievementNoPower.isCompleted {
            // Player scored at least 3000 points w/o power ups
            achievementNoPower.percentComplete = 100.0
            achievementNoPower.showsCompletionBanner = true
            GKAchievement.report([achievementNoPower], withCompletionHandler: nil)
        }
        
        if score >= 1000 && misses == 0 && !achievementAccurate.isCompleted {
            // Player scored at least 1000 points w/o missing
            achievementAccurate.percentComplete = 100.0
            achievementAccurate.showsCompletionBanner = true
            GKAchievement.report([achievementAccurate], withCompletionHandler: nil)
        }
        
        if meteorsHit >= 10 && !achievementMeteor.isCompleted {
            // Player hit 10 meteors in a row
            achievementMeteor.percentComplete = 100.0
            achievementMeteor.showsCompletionBanner = true
            GKAchievement.report([achievementMeteor], withCompletionHandler: nil)
        }
        
        if satellitesHit >= 10 && !achievementSatellite.isCompleted {
            // Player hit 10 satellites in a row
            achievementSatellite.percentComplete = 100.0
            achievementSatellite.showsCompletionBanner = true
            GKAchievement.report([achievementSatellite], withCompletionHandler: nil)
        }
        
        if rocketsHit >= 10 && !achievementRocket.isCompleted {
            // Player hit 10 rockets in a row
            achievementRocket.percentComplete = 100.0
            achievementRocket.showsCompletionBanner = true
            GKAchievement.report([achievementRocket], withCompletionHandler: nil)
        }
        
        if ufosHit >= 10 && !achievementUFO.isCompleted {
            // Player hit 10 ufos in a row
            achievementUFO.percentComplete = 100.0
            achievementUFO.showsCompletionBanner = true
            GKAchievement.report([achievementUFO], withCompletionHandler: nil)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if gameState == .paused {
            self.isPaused = true // When phone wakes up from sleep, scene continues to be paused
            return
        }
        
        // Only have pause box if paused
        self.boxPause.isHidden = true
        
        // Only have game over box if game over
        if gameState == .gameOver {
            self.boxGameOver.position.x = 0
            return
        }
        
        // The rest of update is only when game is active
        if Options.motionConstant == 0 {
            UserDefaults().set(15, forKey: "motionConstant") // Default value
            Options.motionConstant = UserDefaults().double(forKey: "motionConstant")
        }
        
        if Options.controlScheme == 0 {
            joystick.isHidden = true
            guard let motion = motionManager.accelerometerData else {
                return // Accelerometer isn't ready until the next frame
            }
            player.position.x += CGFloat(Double(motion.acceleration.x) * Options.motionConstant)
        } else {
            joystick.isHidden = false
            player.position.x += joystick.moveRight(speed: movementSpeed)
            player.position.x -= joystick.moveLeft(speed: movementSpeed)
        }
        
        thrusters.position = CGPoint(x: player.position.x, y: player.position.y - 45) // Fire moves alongside player
        if thrusters.position.x >= 111 { thrusters.position.x = 111 }
        else if thrusters.position.x <= -111 { thrusters.position.x = -111 }
        
        scrollWorld()
        spawnEnemy()
        spawnPowerUp()
        
        if messageTime > 0 { // Can hit more meteors without affecting timer
            messageTime += fixedDelta
            
            // After 1 second, the message disappears
            if messageTime >= 1 {
                if currentMessage == startMessage {
                    startMessage.removeFromParent()
                } else {
                    powerupMessage.removeFromParent()
                }
                messageTime = 0 // Reset time for any future messages
            }
        }
        
        if gameStart {
            enemySpawnTimer += fixedDelta
            powerSpawnTimer += fixedDelta
            
            for (enemy, speed) in enemySpeed {
                // Overtime, enemies speed up to increase difficulty
                if speed > 0 {
                    enemySpeed[enemy] = speed + 0.01
                } else {
                    enemySpeed[enemy] = speed - 0.01
                }
            }
        }
        
        if isTouching {
            touchTime += fixedDelta
            
            if touchTime >= timeBetweenBlasts {
                shoot()
                touchTime = 0
            }
        }
        
        if isInvincible {
            fadeTime += fixedDelta
            player.physicsBody?.contactTestBitMask = 0
            
            if fadeTime >= 2 {
                player.physicsBody?.contactTestBitMask = 1016 // Update whenever physics masks are modified
                fadeTime = 0
                isInvincible = false
            }
        }
        
        rocketAI()
        ufoAI()
        checkGCAchievements()
        
        if hasPower["health"]! { powerHealth() }
        else if hasPower["rapidFire"]! { powerRapidFire() }
        else if hasPower["spread"]! { powerSpreadShot() }
        else if hasPower["invincible"]! { powerInvincible() }
    }
    
    func playerScoreUpdate() {
        // Called once player loses
        if score >= 0 { addChild(highScoreLabel) }
        else { addChild(lowScoreLabel) }
        let highScore = UserDefaults().integer(forKey: "highscore")
        let lowScore = UserDefaults().integer(forKey: "lowscore")
        
        if score > highScore {
            UserDefaults().set(score, forKey: "highscore") // New high score set
            highScoreLabel.text = "High Score: \(score)"
            addChild(newRecordLabel)
        } else if score < lowScore {
            UserDefaults().set(score, forKey: "lowscore") // New low score set
            lowScoreLabel.text = "Low Score: \(score)"
            addChild(newRecordLabel)
        }
        // Make sure user defaults are loaded into leaderboards
        GameViewController.submitToGC(score: UserDefaults().integer(forKey: "highscore"), leaderboard: GameViewController.HIGH_LEADERBOARD_ID)
        GameViewController.submitToGC(score: UserDefaults().integer(forKey: "lowscore"), leaderboard: GameViewController.LOW_LEADERBOARD_ID)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Called when two bodies make contact
        if gameState != .active { return }
        
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        // If player decides to go insane, nodes won't even be ready!
        guard let nodeA = contactA.node else { return }
        guard let nodeB = contactB.node else { return }
        
        // Player is doing damage
        if nodeA.name == "attack" && nodeB.name == "initialMeteor" || nodeA.name == "initialMeteor" && nodeB.name == "attack" {
            self.soundQueue.addOperation {
                self.soundEffects["explosion"]?.track?.prepareToPlay()
                self.soundEffects["explosion"]?.track?.play()
            }
            
            if nodeA.name == "initialMeteor" {
                contactA.categoryBitMask = 0 // Once hit, the enemy can't be hit mid-explosion
                nodeA.run(SKAction.sequence([SKAction(named: "Explode")!, SKAction.removeFromParent()]))
                nodeB.removeFromParent()
            } else {
                contactB.categoryBitMask = 0
                nodeB.run(SKAction.sequence([SKAction(named: "Explode")!, SKAction.removeFromParent()]))
                nodeA.removeFromParent()
            }
            
            numberOfBlasts -= 1
            initialMeteorsHit += 1
            hits += 1
            if initialMeteorsHit == 3 {
                addChild(startMessage) // Player has completed tutorial section
                currentMessage = startMessage
                scoreLabel.isHidden = false
                messageTime += fixedDelta
                gameStart = true
            }
        }
        
        if nodeA.name == "attack" && nodeB.name == "meteor" || nodeA.name == "meteor" && nodeB.name == "attack" {
            self.soundQueue.addOperation {
                self.soundEffects["explosion"]?.track?.prepareToPlay()
                self.soundEffects["explosion"]?.track?.play()
            }
            
            if nodeA.name == "meteor" {
                contactA.categoryBitMask = 0
                nodeA.run(SKAction.sequence([SKAction(named: "Explode")!, SKAction.removeFromParent()]))
                nodeB.removeFromParent()
            } else {
                contactB.categoryBitMask = 0
                nodeB.run(SKAction.sequence([SKAction(named: "Explode")!, SKAction.removeFromParent()]))
                nodeA.removeFromParent()
            }
            
            meteorsHit += 1
            satellitesHit = 0
            rocketsHit = 0
            ufosHit = 0
            numberOfBlasts -= 1
            hits += 1
            score += 1
        }
        
        if nodeA.name == "attack" && nodeB.name == "satellite" || nodeA.name == "satellite" && nodeB.name == "attack" {
            self.soundQueue.addOperation {
                self.soundEffects["explosion"]?.track?.prepareToPlay()
                self.soundEffects["explosion"]?.track?.play()
            }
            
            if nodeA.name == "satellite" {
                contactA.categoryBitMask = 0
                nodeA.run(SKAction.sequence([SKAction(named: "Explode")!, SKAction.removeFromParent()]))
                nodeB.removeFromParent()
            } else {
                contactB.categoryBitMask = 0
                nodeB.run(SKAction.sequence([SKAction(named: "Explode")!, SKAction.removeFromParent()]))
                nodeA.removeFromParent()
            }
            
            meteorsHit = 0
            satellitesHit += 1
            rocketsHit = 0
            ufosHit = 0
            numberOfBlasts -= 1
            hits += 1
            score += 5
        }
        
        if nodeA.name == "attack" && nodeB.name == "rocket" || nodeA.name == "rocket" && nodeB.name == "attack" {
            self.soundQueue.addOperation {
                self.soundEffects["explosion"]?.track?.prepareToPlay()
                self.soundEffects["explosion"]?.track?.play()
            }
            
            if nodeA.name == "rocket" {
                contactA.categoryBitMask = 0
                guard let rocketIndex = rocketArray.index(of: nodeA as! SKSpriteNode) else { return }
                rocketArray.remove(at: rocketIndex)
                nodeA.run(SKAction.sequence([SKAction(named: "Explode")!, SKAction.removeFromParent()]))
                nodeB.removeFromParent()
            } else {
                contactB.categoryBitMask = 0
                guard let rocketIndex = rocketArray.index(of: nodeB as! SKSpriteNode) else { return }
                rocketArray.remove(at: rocketIndex)
                nodeB.run(SKAction.sequence([SKAction(named: "Explode")!, SKAction.removeFromParent()]))
                nodeA.removeFromParent()
            }
            
            meteorsHit = 0
            satellitesHit = 0
            rocketsHit += 1
            ufosHit = 0
            numberOfBlasts -= 1
            hits += 1
            score += 10
        }
        
        if nodeA.name == "attack" && nodeB.name == "ufo" || nodeA.name == "ufo" && nodeB.name == "attack" {
            self.soundQueue.addOperation {
                self.soundEffects["explosion"]?.track?.prepareToPlay()
                self.soundEffects["explosion"]?.track?.play()
            }
            
            if nodeA.name == "ufo" {
                contactA.categoryBitMask = 0
                guard let ufoIndex = ufoArray.index(of: nodeA as! SKSpriteNode) else { return }
                ufoData.remove(at: ufoIndex)
                ufoArray.remove(at: ufoIndex)
                nodeA.run(SKAction.sequence([SKAction(named: "Explode")!, SKAction.removeFromParent()]))
                nodeB.removeFromParent()
            } else {
                contactB.categoryBitMask = 0
                guard let ufoIndex = ufoArray.index(of: nodeB as! SKSpriteNode) else { return }
                ufoData.remove(at: ufoIndex)
                ufoArray.remove(at: ufoIndex)
                nodeB.run(SKAction.sequence([SKAction(named: "Explode")!, SKAction.removeFromParent()]))
                nodeA.removeFromParent()
            }
            
            meteorsHit = 0
            satellitesHit = 0
            rocketsHit = 0
            ufosHit += 1
            numberOfBlasts -= 1
            hits += 1
            score += 20
        }
        
        // Satellite hits the side
        if nodeA.name == "satellite" && nodeB.name == "boundarySide" || nodeA.name == "boundarySide" && nodeB.name == "satellite" {
            enemySpeed["satelliteX"] = -enemySpeed["satelliteX"]!
        }
        
        // Blasts are going offscreen
        if nodeA.name == "attack" && nodeB.name == "boundary" || nodeA.name == "boundary" && nodeB.name == "attack" {
            if nodeA.name == "attack" { nodeA.removeFromParent() }
            else { nodeB.removeFromParent() }
            numberOfBlasts -= 1
            misses += 1
        }
        
        if nodeA.name == "ufoAttack" && nodeB.name == "boundary" || nodeA.name == "boundary" && nodeB.name == "ufoAttack" {
            if nodeA.name == "ufoAttack" { nodeA.removeFromParent() }
            else { nodeB.removeFromParent() }
        }
        
        // Enemies and power ups are going offscreen
        if (nodeA.name == "meteor" || nodeA.name == "satellite" || nodeA.name == "rocket" || nodeA.name == "ufo" || nodeA.name == "powerupHealth" || nodeA.name == "powerupRapidFire" || nodeA.name == "powerupSpread" || nodeA.name == "powerupInvincible") && nodeB.name == "boundary" ||
            nodeA.name == "boundary" && (nodeB.name == "meteor" || nodeB.name == "satellite" || nodeB.name == "rocket" || nodeB.name == "ufo" || nodeB.name == "powerupHealth" || nodeB.name == "powerupRapidFire" || nodeB.name == "powerupSpread" || nodeB.name == "powerupInvincible") {
            if nodeA.name == "rocket" {
                guard let rocketIndex = rocketArray.index(of: nodeA as! SKSpriteNode) else { return }
                rocketArray.remove(at: rocketIndex)
            } else if nodeB.name == "rocket" {
                guard let rocketIndex = rocketArray.index(of: nodeB as! SKSpriteNode) else { return }
                rocketArray.remove(at: rocketIndex)
            } else if nodeA.name == "ufo" {
                guard let ufoIndex = ufoArray.index(of: nodeA as! SKSpriteNode) else { return }
                ufoData.remove(at: ufoIndex)
                ufoArray.remove(at: ufoIndex)
            } else if nodeB.name == "ufo" {
                guard let ufoIndex = ufoArray.index(of: nodeB as! SKSpriteNode) else { return }
                ufoData.remove(at: ufoIndex)
                ufoArray.remove(at: ufoIndex)
            }
            
            if nodeA.name == "boundary" { nodeB.removeFromParent() }
            else { nodeA.removeFromParent() }
            score -= 1 // Player is punished for not shooting enemies
        }
        
        // Player has powered up
        if nodeA.name == "player" && (nodeB.name == "powerupHealth" || nodeB.name == "powerupRapidFire" || nodeB.name == "powerupSpread" || nodeB.name == "powerupInvincible") ||
            (nodeA.name == "powerupHealth" || nodeA.name == "powerupRapidFire" || nodeA.name == "powerupSpread" || nodeA.name == "powerupInvincible") && nodeB.name == "player" {
            self.soundQueue.addOperation {
                self.soundEffects["power up"]?.track?.prepareToPlay()
                self.soundEffects["power up"]?.track?.play()
            }
            touchedPower = true
            
            if nodeA.name == "powerupHealth" || nodeB.name == "powerupHealth" {
                powerupMessage.text = "Health"
                addChild(powerupMessage)
                messageTime += fixedDelta
                hasPower["health"] = true
            } else if nodeA.name == "powerupRapidFire" || nodeB.name == "powerupRapidFire" {
                powerupMessage.text = "Rapid Fire"
                addChild(powerupMessage)
                messageTime += fixedDelta
                timeLabel.isHidden = false
                hasPower["rapidFire"] = true
            } else if nodeA.name == "powerupSpread" || nodeB.name == "powerupSpread" {
                powerupMessage.text = "Spread Shot"
                addChild(powerupMessage)
                messageTime += fixedDelta
                timeLabel.isHidden = false
                hasPower["spread"] = true
            } else if nodeA.name == "powerupInvincible" || nodeB.name == "powerupInvincible" {
                powerupMessage.text = "Invincibility"
                addChild(powerupMessage)
                messageTime += fixedDelta
                timeLabel.isHidden = false
                hasPower["invincible"] = true
            }
            
            currentMessage = powerupMessage
            if nodeA.name == "player" { nodeB.removeFromParent() }
            else { nodeA.removeFromParent() }
        }
        
        // Player is taking damage from enemies
        if nodeA.name == "player" && (nodeB.name == "meteor" || nodeB.name == "satellite" || nodeB.name == "rocket" || nodeB.name == "ufo" || nodeB.name == "ufoAttack") ||
            (nodeA.name == "meteor" || nodeA.name == "satellite" || nodeA.name == "rocket" || nodeA.name == "ufo" || nodeA.name == "ufoAttack") && nodeB.name == "player" {
            self.soundQueue.addOperation {
                self.soundEffects["explosion"]?.track?.prepareToPlay()
                self.soundEffects["explosion"]?.track?.play()
            }
            
            if nodeA.name == "rocket" {
                guard let rocketIndex = rocketArray.index(of: nodeA as! SKSpriteNode) else { return }
                rocketArray.remove(at: rocketIndex)
            } else if nodeB.name == "rocket" {
                guard let rocketIndex = rocketArray.index(of: nodeB as! SKSpriteNode) else { return }
                rocketArray.remove(at: rocketIndex)
            } else if nodeA.name == "ufo" {
                guard let ufoIndex = ufoArray.index(of: nodeA as! SKSpriteNode) else { return }
                ufoData.remove(at: ufoIndex)
                ufoArray.remove(at: ufoIndex)
            } else if nodeB.name == "ufo" {
                guard let ufoIndex = ufoArray.index(of: nodeB as! SKSpriteNode) else { return }
                ufoData.remove(at: ufoIndex)
                ufoArray.remove(at: ufoIndex)
            }
            
            // Player invulnerability period
            if nodeA.name == "player" {
                nodeA.run(SKAction(named: "Invincibility")!)
                contactB.categoryBitMask = 0
                nodeB.run(SKAction.sequence([SKAction(named: "Explode")!, SKAction.removeFromParent()]))
            } else {
                nodeB.run(SKAction(named: "Invincibility")!)
                contactA.categoryBitMask = 0
                nodeA.run(SKAction.sequence([SKAction(named: "Explode")!, SKAction.removeFromParent()]))
            }
            
            isInvincible = true
            healthBar.xScale -= 0.18
            
            // When the player is low on health, the health bar turns red
            if healthBar.xScale <= 1 {
                healthBar.texture = SKTexture(imageNamed: "red_button11")
            }
            
            if healthBar.xScale <= 0.1 {
                if nodeA.name == "player" {
                    contactA.categoryBitMask = 0
                    nodeA.run(SKAction.sequence([SKAction(named: "DestroyShip")!, SKAction.removeFromParent()]))
                } else {
                    contactB.categoryBitMask = 0
                    nodeB.run(SKAction.sequence([SKAction(named: "DestroyShip")!, SKAction.removeFromParent()]))
                }
                
                thrusters.removeFromParent()
                gameState = .gameOver
                playerScoreUpdate()
                
                addChild(hitsMessage)
                hitsMessage.text = "Hits: " + String(format: "%.0f", hits)
                addChild(missMessage)
                missMessage.text = "Misses: " + String(format: "%.0f", misses)
                addChild(ratioMessage) // Round to 2 decimal places
                ratioMessage.text = "Hit-Miss Ratio: " + String(format: "%.2f", hits/(hits + misses))
            }
        }
    }
}
