//
//  GameScene.swift
//  Captain Conundrum
//
//  Created by Basanta Chaudhuri on 7/24/17.
//  Copyright © 2017 Abhishek Chaudhuri. All rights reserved.
//

import SpriteKit
import CoreMotion
import AVFoundation

enum GameState {
    case active, paused, gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    // Player and enemies
    var player: SKSpriteNode!
    var initialMeteor: SKSpriteNode!
    var meteor: SKSpriteNode!
    var satellite: SKSpriteNode!
    var rocket: SKSpriteNode!
    var ufo: SKSpriteNode!
    let thrusters = SKEmitterNode(fileNamed: "Fire")!
    
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
    var enemySpeed: [String: Double] = [
        // Info about each enemy
        "meteor": -100,
        "satelliteX": -200, "satelliteY": -200,
        "rocket": -300,
        "ufo+": 150, "ufo-": -150
    ]
    
    // Timers (in seconds)
    var messageTime: CFTimeInterval = 0 // Start message
    var spawnTimer:  CFTimeInterval = 0 // Enemy spawning
    var touchTime:   CFTimeInterval = 0 // Holding down touch
    var fadeTime:    CFTimeInterval = 0 // Invulnerable to damage
    
    // Music
    var soundEffects: [String: (file: String, track: AVAudioPlayer?)] = [
        // Stores all music tracks
        "select": ("click1", nil),
        "incoming": ("highDown", nil),
        "exit": ("switch34", nil),
        "attack": ("laser5", nil),
        "enemy attack": ("laser7", nil),
        "explosion": ("cc0_explosion_large_gun_powder", nil)
    ]
    
    // Other
    var scoreLabel: SKLabelNode!
    var healthBar: SKSpriteNode!
    var motionManager: CMMotionManager!
    var initialMeteorsHit = 0 // Keeps track of initial meteor herd
    var numberOfBlasts = 0
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
    
    var attack: SKSpriteNode = {
        let blast = SKSpriteNode(imageNamed: "laserRed02")
        blast.name = "attack"
        blast.zPosition = 1
        blast.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: blast.size.width, height: blast.size.height))
        blast.physicsBody?.allowsRotation = false
        blast.physicsBody?.affectedByGravity = false
        blast.physicsBody?.categoryBitMask = 4
        blast.physicsBody?.collisionBitMask = 4
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
        blast.physicsBody?.collisionBitMask = 256
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
        
        buttonPause = childNode(withName: "buttonPause") as! MSButtonNode
        boxPause = childNode(withName: "boxPause")
        buttonContinue = boxPause.childNode(withName: "buttonContinue") as! MSButtonNode
        buttonQuit = boxPause.childNode(withName: "buttonQuit") as! MSButtonNode
        boxGameOver = childNode(withName: "boxGameOver")
        buttonRetry = boxGameOver.childNode(withName: "buttonRetry") as! MSButtonNode
        buttonQuit2 = boxGameOver.childNode(withName: "buttonQuit2") as! MSButtonNode
        
        scrollLayer = childNode(withName: "scrollLayer")
        scoreLabel = childNode(withName: "scoreLabel") as! SKLabelNode
        healthBar = childNode(withName: "healthBar") as! SKSpriteNode
        
        for (key: sound, value: (file: file, track: _)) in soundEffects {
            // Get sound effects ready
            let soundFilePath = Bundle.main.path(forResource: file, ofType: "caf")!
            let soundFileURL = URL(fileURLWithPath: soundFilePath)
            
            do {
                let player = try AVAudioPlayer(contentsOf: soundFileURL)
                soundEffects[sound]?.track = player
                let track = soundEffects[sound]?.track ?? player // Causes parameter to be mutable
                track.numberOfLoops = 0 // No loop
                track.prepareToPlay()
            } catch {
                print("Music can't be played.")
            }
        }
        
        buttonPause.selectedHandler = { [unowned self] in
            self.soundEffects["select"]?.track?.play()
            if self.gameState == .gameOver { return }
            self.gameState = .paused
            self.boxPause.isHidden = false
            self.isPaused = true
        }
        
        buttonContinue.selectedHandler = { [unowned self] in
            self.soundEffects["select"]?.track?.play()
            self.gameState = .active
            self.boxPause.isHidden = true
            self.isPaused = false
        }
        
        buttonQuit.selectedHandler = { [unowned self] in
            self.soundEffects["exit"]?.track?.play()
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
            self.isPaused = false
            
            skView.presentScene(scene, transition: fade)
        }
        
        buttonRetry.selectedHandler = { [unowned self] in
            self.soundEffects["select"]?.track?.play()
            self.boxGameOver.position.x = -320
            
            guard let skView = self.view as SKView! else {
                print("Could not get SKview")
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
        
        buttonQuit2.selectedHandler = buttonQuit.selectedHandler
        
        physicsWorld.contactDelegate = self
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        thrusters.position.y = player.position.y - 45
        addChild(thrusters)
    }
    
    func shoot() {
        if numberOfBlasts >= 3 { return } // Only 3 lasers allowed on screen at once
        // Copies allow for multiple attacks on screen
        let multiAttack = attack.copy() as! SKSpriteNode
        soundEffects["attack"]?.track?.play()
        addChild(multiAttack)
        multiAttack.position = player.position
        multiAttack.physicsBody?.velocity = CGVector(dx: 0, dy: 500)
        numberOfBlasts += 1
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
        if spawnTimer < 1 { return }
        
        let enemy = arc4random_uniform(4) // 4 enemies to choose from
        let enemyPosition = CGPoint(x: CGFloat.random(min: -117, max: 117), y: 305)
        soundEffects["incoming"]?.track?.play()
        
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
        
        spawnTimer = 0
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
                soundEffects["enemy attack"]?.track?.play()
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
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if gameState == .paused { return }
        
        // Only have pause box if paused
        self.boxPause.isHidden = true
        
        // Only have game over box if game over
        if gameState == .gameOver {
            self.boxGameOver.position.x = 0
            return
        }
        
        // The rest of update is only when game is active
        guard let motion = motionManager.accelerometerData else {
            return // Accelerometer isn't ready until the next frame
        }
        player.position.x += CGFloat(Double(motion.acceleration.x) * 15)
        thrusters.position = CGPoint(x: player.position.x, y: player.position.y - 45) // Fire moves alongside player
        
        scrollWorld()
        spawnEnemy()
        
        if messageTime > 0 { // Can hit more meteors without affecting start timer
            messageTime += fixedDelta
            
            // After 1 second, Start disappears
            if messageTime >= 1 {
                startMessage.removeFromParent()
                messageTime = 0 // Reset time for any future messages
            }
        }
        
        if gameStart {
            spawnTimer += fixedDelta
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
            
            if touchTime >= 0.5 { // Auto-fire every 0.5 seconds
                shoot()
                touchTime = 0
            }
        }
        
        if isInvincible {
            fadeTime += fixedDelta
            player.physicsBody?.contactTestBitMask = 0
            
            if fadeTime >= 2 {
                player.physicsBody?.contactTestBitMask = 504
                fadeTime = 0
                isInvincible = false
            }
        }
        
        rocketAI()
        ufoAI()
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
            soundEffects["explosion"]?.track?.play()
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
                scoreLabel.isHidden = false
                messageTime += fixedDelta
                spawnTimer += fixedDelta
                gameStart = true
            }
        }
        
        if nodeA.name == "attack" && nodeB.name == "meteor" || nodeA.name == "meteor" && nodeB.name == "attack" {
            soundEffects["explosion"]?.track?.play()
            if nodeA.name == "meteor" {
                contactA.categoryBitMask = 0
                nodeA.run(SKAction.sequence([SKAction(named: "Explode")!, SKAction.removeFromParent()]))
                nodeB.removeFromParent()
            } else {
                contactB.categoryBitMask = 0
                nodeB.run(SKAction.sequence([SKAction(named: "Explode")!, SKAction.removeFromParent()]))
                nodeA.removeFromParent()
            }
            
            numberOfBlasts -= 1
            hits += 1
            score += 1
        }
        
        if nodeA.name == "attack" && nodeB.name == "satellite" || nodeA.name == "satellite" && nodeB.name == "attack" {
            soundEffects["explosion"]?.track?.play()
            if nodeA.name == "satellite" {
                contactA.categoryBitMask = 0
                nodeA.run(SKAction.sequence([SKAction(named: "Explode")!, SKAction.removeFromParent()]))
                nodeB.removeFromParent()
            } else {
                contactB.categoryBitMask = 0
                nodeB.run(SKAction.sequence([SKAction(named: "Explode")!, SKAction.removeFromParent()]))
                nodeA.removeFromParent()
            }
            
            numberOfBlasts -= 1
            hits += 1
            score += 5
        }
        
        if nodeA.name == "attack" && nodeB.name == "rocket" || nodeA.name == "rocket" && nodeB.name == "attack" {
            soundEffects["explosion"]?.track?.play()
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
            
            numberOfBlasts -= 1
            hits += 1
            score += 10
        }
        
        if nodeA.name == "attack" && nodeB.name == "ufo" || nodeA.name == "ufo" && nodeB.name == "attack" {
            soundEffects["explosion"]?.track?.play()
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
        
        // Enemies are going offscreen
        if nodeA.name == "meteor" && nodeB.name == "boundary" || nodeA.name == "boundary" && nodeB.name == "meteor" || nodeA.name == "satellite" && nodeB.name == "boundary" || nodeA.name == "boundary" && nodeB.name == "satellite" || nodeA.name == "rocket" && nodeB.name == "boundary" || nodeA.name == "boundary" && nodeB.name == "rocket" || nodeA.name == "ufo" && nodeB.name == "boundary" || nodeA.name == "boundary" && nodeB.name == "ufo" {
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
        
        // Player is taking damage (except with the boundaries)
        if nodeA.name == "player" && (nodeB.name != "boundary" && nodeB.name != "boundarySide") || (nodeA.name != "boundary" && nodeA.name != "boundarySide") && nodeB.name == "player" {
            soundEffects["explosion"]?.track?.play()
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
            
            // Player invincibility period
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
            healthBar.yScale -= 0.25
            
            // When the player is low on health, the health bar turns red
            if healthBar.yScale <= 1.25 {
                healthBar.texture = SKTexture(imageNamed: "laserRed02")
            }
            
            if healthBar.yScale <= 0 {
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
