//
//  GameViewController.swift
//  Breakout
//
//  Created by Rui Li on 24/9/18.
//  Copyright © 2018 Rui Li. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFit
                scene.anchorPoint = CGPoint(x: 0, y: 0)
                
                // Present the scene
                view.presentScene(scene)
            }
            
            view.preferredFramesPerSecond = 60
            
            view.showsFPS = true
            view.showsNodeCount = true
            view.showsPhysics = true
            view.showsDrawCount = true
            view.showsFields = true
            view.showsQuadCount = true
            
            view.ignoresSiblingOrder = true
            
            view.backgroundColor = UIColor.blue
            
            
        }
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }
}
