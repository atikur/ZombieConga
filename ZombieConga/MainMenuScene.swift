//
//  MainMenuScene.swift
//  ZombieConga
//
//  Created by Atikur Rahman on 1/20/15.
//  Copyright (c) 2015 Atikur Rahman. All rights reserved.
//

import UIKit
import SpriteKit

class MainMenuScene: SKScene {
   
    override func didMoveToView(view: SKView) {
        let background = SKSpriteNode(imageNamed: "MainMenu")
        background.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        self.addChild(background)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        sceneTapped()
    }
    
    func sceneTapped() {
        let block = SKAction.runBlock {
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = self.scaleMode
            let doorWay = SKTransition.doorwayWithDuration(1.5)
            self.view?.presentScene(gameScene, transition: doorWay)
        }
        self.runAction(block)
    }
}
