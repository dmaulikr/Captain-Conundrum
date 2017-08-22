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
//import Crashlytics // If using Answers with Crashlytics
import Answers // If using Answers without Crashlytics
import GameKit // For Game Center


class GameViewController: UIViewController, GKGameCenterControllerDelegate {
    static var backgroundMusic: AVAudioPlayer! // Can be changed in options
    
    /* Variables */
    var gcEnabled = Bool() // Check if the user has Game Center enabled
    var gcDefaultLeaderBoard = String() // Check the default leaderboardID
    
    // IMPORTANT: replace the red string below with your own Leaderboard ID (the one you've set in iTunes Connect)
    static let HIGH_LEADERBOARD_ID = "com.highscore.captainconundrum"
    static let LOW_LEADERBOARD_ID = "com.lowscore.captainconundrum"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*let button = UIButton(type: UIButtonType.roundedRect)
        button.setTitle("Trigger Key Metric", for: [])
        button.addTarget(self, action: #selector(self.anImportantUserAction), for: UIControlEvents.touchUpInside)
        button.sizeToFit()
        button.center = self.view.center
        view.addSubview(button)
        
        // TODO: Track the user action that is important for you.
        Answers.logContentView(withName: "Tweet", contentType: "Video", contentId: "1234", customAttributes: ["Favorites Count":20, "Screen Orientation":"Landscape"])*/
        
        // Call the GC authentication controller
        authenticateLocalPlayer()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'MainMenu.sks'
            if let scene = SKScene(fileNamed: "MainMenu") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFit
                
                // Present the scene
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            
            // For debugging purposes
            // view.showsFPS = true
            // view.showsNodeCount = true
            
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
    
    func anImportantUserAction() {
        
        // TODO: Move this method and customize the name and parameters to track your key metrics
        //       Use your own string attributes to track common values over time
        //       Use your own number attributes to track median value over time
        Answers.logCustomEvent(withName: "Video Played", customAttributes: ["Category":"Comedy", "Length":350])
    }
    
    // MARK: - AUTHENTICATE LOCAL PLAYER
    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
        
        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            if((ViewController) != nil) {
                // 1. Show login if player is not logged in
                self.present(ViewController!, animated: true, completion: nil)
            } else if (localPlayer.isAuthenticated) {
                // 2. Player is already authenticated & logged in, load game center
                self.gcEnabled = true
                
                // Get the default leaderboard ID
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifer, error) in
                    if error != nil { print(error!)
                    } else { self.gcDefaultLeaderBoard = leaderboardIdentifer! }
                })
                
            } else {
                // 3. Game center is not enabled on the users device
                self.gcEnabled = false
                print("Local player could not be authenticated!")
                print(error!)
            }
        }
    }
    
    // MARK: - SUBMIT THE UPDATED SCORE TO GAME CENTER
    static func submitToGC(score: Int, leaderboard: String) {
        // Submit score to the appropriate GC leaderboard
        let bestScoreInt = GKScore(leaderboardIdentifier: leaderboard)
        bestScoreInt.value = Int64(score)
        GKScore.report([bestScoreInt], withCompletionHandler: nil)
    }
    
    // Delegate to dismiss the GC controller
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - OPEN GAME CENTER LEADERBOARD
    /*func checkGCLeaderboard() {
        let gcVC = GKGameCenterViewController()
        gcVC.gameCenterDelegate = self
        gcVC.viewState = .leaderboards
        // User will see all leaderboards (change gcVC.leaderboardIdentifier for specific one)
        present(gcVC, animated: true, completion: nil)
    }*/

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
