//
//  MainMenu.swift
//  Captain Conundrum
//
//  Created by Basanta Chaudhuri on 7/24/17.
//  Copyright © 2017 Abhishek Chaudhuri. All rights reserved.
//

import SpriteKit

class MainMenu: SKScene {
    var star: SKSpriteNode!
    var buttonStart: MSButtonNode!
    var buttonOptions: MSButtonNode!
    
    override func didMove(to view: SKView) {
        star = childNode(withName: "star") as! SKSpriteNode
        buttonStart = childNode(withName: "buttonStart") as! MSButtonNode
        buttonOptions = childNode(withName: "buttonOptions") as! MSButtonNode
        
        buttonStart.selectedHandler = {
            self.loadGame()
        }
        
        buttonOptions.selectedHandler = {
            self.loadOptions()
        }
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
        
        skView.presentScene(scene)
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
        
        skView.presentScene(scene)
    }
}
