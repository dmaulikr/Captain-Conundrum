//
//  GameViewController.swift
//  Captain Conundrum
//
//  Created by Basanta Chaudhuri on 7/24/17.
//  Copyright © 2017 Abhishek Chaudhuri. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import AVFoundation // For AVAudioPlayer()

class GameViewController: UIViewController {
    static var backgroundMusic: AVAudioPlayer! // Can be changed in options

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'MainMenu.sks'
            if let scene = SKScene(fileNamed: "MainMenu") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFit
                
                // Present the scene
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
            
            // Play music in the background
            let soundFilePath = Bundle.main.path(forResource: "techological", ofType: "caf")!
            let soundFileURL = URL(fileURLWithPath: soundFilePath)
            
            do {
                let player = try AVAudioPlayer(contentsOf: soundFileURL)
                GameViewController.backgroundMusic = player
                GameViewController.backgroundMusic.numberOfLoops = -1 // Infinite loop
                GameViewController.backgroundMusic.prepareToPlay()
                GameViewController.backgroundMusic.play()
            } catch {
                print("Music can't be played.")
            }
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
