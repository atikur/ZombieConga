//
//  GameScene.swift
//  ZombieConga
//
//  Created by Atikur Rahman on 12/18/14.
//  Copyright (c) 2014 Atikur Rahman. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    
    var lastUpdateTime: NSTimeInterval = 0
    var dt: NSTimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0
    var velocity = CGPointZero
    
    override func didMoveToView(view: SKView) {
        backgroundColor = SKColor.whiteColor()
        
        // add background sprite
        let background = SKSpriteNode(imageNamed: "background1")
        background.position = CGPointMake(size.width/2, size.height/2)
        background.zPosition = -1
        addChild(background)
        
        // add zombie
        zombie.position = CGPointMake(400, 400)
        addChild(zombie)
    }
    
    override func update(currentTime: NSTimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        println("\(dt*1000) milliseconds since last update")
        
        moveSprite(zombie, velocity: CGPoint(x: zombieMovePointsPerSec, y: 0))
    }
    
    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dt), y: velocity.y * CGFloat(dt))
        println("Amount to move: \(amountToMove)")
        sprite.position = CGPoint(x: sprite.position.x + amountToMove.x, y: sprite.position.y + amountToMove.y)
    }
}