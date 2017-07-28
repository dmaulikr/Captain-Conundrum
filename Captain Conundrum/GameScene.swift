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
    // Player and enemies
    var player: SKSpriteNode!
    var initialMeteor: SKSpriteNode!
    var meteor: SKSpriteNode!
    var satellite: SKSpriteNode!
    var rocket: SKSpriteNode!
    var ufo: SKSpriteNode!
    
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
    var fixedDelta: CFTimeInterval = 1.0 / 60.0 // 60 FPS
    var scrollSpeed: CGFloat = 100
    var enemySpeed: [Double] = [-100, -200, -300, -150] // Each enemy in order
    
    // Other
    var scoreLabel: SKLabelNode!
    var healthBar: SKSpriteNode!
    var motionManager: CMMotionManager!
    var initialMeteorsHit = 0 // Keeps track of initial meteor herd
    var numberOfBlasts = 0
    var messageTime: CFTimeInterval = 0 // In seconds
    var spawnTimer: CFTimeInterval = 0
    var isTouching = false
    var touchTime: CFTimeInterval = 0
    var gameTimer: CFTimeInterval = 0
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
    
    var newRecordLabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Britannic Bold")
        label.fontSize = 36
        label.fontColor = .green
        label.position = CGPoint(x: 0, y: 125)
        label.zPosition = 2
        label.text = "New Record!"
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
        
        buttonPause.selectedHandler = {
            if self.gameState == .gameOver { return }
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
        
        buttonRetry.selectedHandler = {
            self.boxGameOver.position.x = -286
            
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
    }
    
    func shoot() {
        if numberOfBlasts >= 3 { return } // Only 3 lasers allowed on screen at once
        // Copies allow for multiple attacks on screen
        let multiAttack = attack.copy() as! SKSpriteNode
        addChild(multiAttack)
        multiAttack.position = player.position
        multiAttack.physicsBody?.velocity = CGVector(dx: 0, dy: 500)
        //attack = multiAttack // Will allow any code that involves attack outside function to work
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
        
        switch enemy {
            case 0:
                let newMeteor = meteor.copy() as! SKSpriteNode
                newMeteor.position = enemyPosition
                newMeteor.physicsBody?.velocity = CGVector(dx: 0, dy: enemySpeed[0]) // Fall down slowly
                addChild(newMeteor)
            case 1:
                let newSatellite = satellite.copy() as! SKSpriteNode
                newSatellite.position = enemyPosition
                newSatellite.physicsBody?.velocity = CGVector(dx: 0, dy: enemySpeed[1]) // Move diagonally
                addChild(newSatellite)
            case 2:
                let newRocket = rocket.copy() as! SKSpriteNode
                newRocket.position = enemyPosition
                newRocket.physicsBody?.velocity = CGVector(dx: 0, dy: enemySpeed[2]) // Fall quickly
                addChild(newRocket)
            default:
                let newUFO = ufo.copy() as! SKSpriteNode
                newUFO.position = enemyPosition
                newUFO.physicsBody?.velocity = CGVector(dx: 0, dy: enemySpeed[3]) // Zigzag
                addChild(newUFO)
        }
        
        spawnTimer = fixedDelta
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
        
        guard let motion = motionManager.accelerometerData else {
            return // Accelerometer isn't ready until the next frame
        }
        player.position.x += CGFloat(Double(motion.acceleration.x) * 15)
        
        scrollWorld()
        spawnEnemy()
        
        if messageTime > 0 { // Can hit more meteors without affecting start timer
            messageTime += fixedDelta
        }
        
        // After 1 second, Start disappears
        if messageTime >= 1 {
            startMessage.removeFromParent()
            messageTime = 0 // Reset time for any future messages
        }
        
        // Waiting time before a new enemy shows up
        if spawnTimer > 0 {
            spawnTimer += fixedDelta
        }
        
        if gameTimer > 0 {
            gameTimer += fixedDelta
            
            for enemy in 0...3 {
                enemySpeed[enemy] -= 0.01 // Overtime, enemies speed up to increase difficulty
            }
        }
        
        if isTouching {
            touchTime += fixedDelta
            
            if touchTime >= 0.5 { // Auto-fire every 0.5 seconds
                shoot()
                touchTime = 0
            }
        }
    }
    
    func playerScoreUpdate() {
        // Called once player loses
        addChild(highScoreLabel)
        let highScore = UserDefaults().integer(forKey: "highscore")
        
        if score > highScore {
            UserDefaults().set(score, forKey: "highscore") // New high score set
            highScoreLabel.text = "High Score: \(score)"
            addChild(newRecordLabel)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Called when two bodies make contact
        if gameState != .active { return }
        
        let contactA = contact.bodyA
        let contactB = contact.bodyB
        // If player decides to go insane, nodes won't even be ready!
        guard let nodeA = contactA.node else {
            return
        }
        guard let nodeB = contactB.node else {
            return
        }
        
        // Player is doing damage
        if nodeA.name == "attack" && nodeB.name == "initialMeteor" || nodeA.name == "initialMeteor" && nodeB.name == "attack" {
            nodeA.removeFromParent()
            nodeB.removeFromParent()
            numberOfBlasts -= 1
            initialMeteorsHit += 1
            if initialMeteorsHit == 3 {
                addChild(startMessage) // Player has completed tutorial section
                scoreLabel.isHidden = false
                messageTime += fixedDelta
                spawnTimer += fixedDelta
                gameTimer += fixedDelta
            }
        }
        
        if nodeA.name == "attack" && nodeB.name == "meteor" || nodeA.name == "meteor" && nodeB.name == "attack" {
            nodeA.removeFromParent()
            nodeB.removeFromParent()
            numberOfBlasts -= 1
            score += 1
        }
        
        if nodeA.name == "attack" && nodeB.name == "satellite" || nodeA.name == "satellite" && nodeB.name == "attack" {
            nodeA.removeFromParent()
            nodeB.removeFromParent()
            numberOfBlasts -= 1
            score += 5
        }
        
        if nodeA.name == "attack" && nodeB.name == "rocket" || nodeA.name == "rocket" && nodeB.name == "attack" {
            nodeA.removeFromParent()
            nodeB.removeFromParent()
            numberOfBlasts -= 1
            score += 10
        }
        
        if nodeA.name == "attack" && nodeB.name == "ufo" || nodeA.name == "ufo" && nodeB.name == "attack" {
            nodeA.removeFromParent()
            nodeB.removeFromParent()
            numberOfBlasts -= 1
            score += 20
        }
        
        // Satellite or UFO hits the side
        /*if nodeA.name == "satellite" && nodeB.name == "boundarySide" || nodeA.name == "boundarySide" && nodeB.name == "satellite" {
            
        }*/
        
        // Blasts are going offscreen
        if nodeA.name == "attack" && nodeB.name == "boundary" || nodeA.name == "boundary" && nodeB.name == "attack" {
            if nodeA.name == "attack" { nodeA.removeFromParent() }
            else { nodeB.removeFromParent() }
            numberOfBlasts -= 1
        }
        
        // Enemies are going offscreen
        if nodeA.name == "meteor" && nodeB.name == "boundary" || nodeA.name == "boundary" && nodeB.name == "meteor" || nodeA.name == "satellite" && nodeB.name == "boundary" || nodeA.name == "boundary" && nodeB.name == "satellite" || nodeA.name == "rocket" && nodeB.name == "boundary" || nodeA.name == "boundary" && nodeB.name == "rocket" || nodeA.name == "ufo" && nodeB.name == "boundary" || nodeA.name == "boundary" && nodeB.name == "ufo" {
            if nodeA.name == "boundary" { nodeB.removeFromParent() }
            else { nodeA.removeFromParent() }
        }
        
        // Player is taking damage (except with the boundaries)
        if nodeA.name == "player" && (nodeB.name != "boundary" && nodeB.name != "boundarySide") || (nodeA.name != "boundary" && nodeA.name != "boundarySide") && nodeB.name == "player" {
            if nodeA.name != "player" && nodeA.name != "boundary" { nodeA.removeFromParent() }
            else if nodeB.name != "player" && nodeB.name != "boundary" { nodeB.removeFromParent() }
            
            healthBar.yScale -= 0.25
            // When the player is low on health, the health bar turns red
            if healthBar.yScale <= 1.25 {
                healthBar.texture = SKTexture(imageNamed: "laserRed02")
            }
            if healthBar.yScale <= 0 {
                if nodeA.name == "player" { nodeA.removeFromParent() }
                else { nodeB.removeFromParent() }
                gameState = .gameOver
                playerScoreUpdate()
            }
        }
    }
}
