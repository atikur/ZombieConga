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
    let zombieRotateRadiansPerSec: CGFloat = 4.0 * π
    var velocity = CGPointZero
    
    let playableRect: CGRect
    
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
        
        spawnEnemy()
    }
    
    override func update(currentTime: NSTimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        moveSprite(zombie, velocity: velocity)
        boundsCheckZombie()
        rotateSprite(zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
    }
    
    // MARK: - Zombie
    
    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = velocity * CGFloat(dt)
        sprite.position += amountToMove
    }
    
    func moveZombieTowardLocation(location: CGPoint) {
        // offset vector between the touch location and zombie's current position
        let offset = location - zombie.position
        // length of offset vector
        let length = offset.length()
        // unit vector in the direction of offset vector
        let direction = offset.normalized()
        // updated velocity vector
        velocity = direction * zombieMovePointsPerSec
    }
    
    func boundsCheckZombie() {
        let bottomLeft = CGPoint(x: 0, y: CGRectGetMinY(playableRect))
        let topRight = CGPoint(x: size.width, y: CGRectGetMaxY(playableRect))
        
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    
    func sceneTouched(touchLocation: CGPoint) {
        moveZombieTowardLocation(touchLocation)
    }
    
    func rotateSprite(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        // shortest angle between current and desired direction
        let shortest = shortestAngleBetween(sprite.zRotation, direction.angle)
        var amtToRotate = rotateRadiansPerSec * CGFloat(dt)
        if abs(shortest) < amtToRotate {
            amtToRotate = abs(shortest)
        }
        sprite.zRotation += amtToRotate * shortest.sign()
    }
    
    // MARK: - Enemy
    
    func spawnEnemy() {
        // add enemy sprite
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.position = CGPoint(x: size.width + enemy.size.width/2, y: size.height/2)
        addChild(enemy)
        
        let actionMidMove = SKAction.moveByX(
            -size.width/2 - enemy.size.width/2,
            y: -CGRectGetHeight(playableRect)/2 + enemy.size.height/2,
            duration: 1.0)
        
        let actionMove = SKAction.moveByX(
            -size.width/2 - enemy.size.width/2,
            y: CGRectGetHeight(playableRect)/2 - enemy.size.height/2,
            duration: 1.0)
        
        let wait = SKAction.waitForDuration(0.25)
        
        let logMessage = SKAction.runBlock({
            println("Reached bottom!")
        })
        
        let reverseMid = actionMidMove.reversedAction()
        let reverseMove = actionMove.reversedAction()
        
        let halfSequence = SKAction.sequence([actionMidMove, logMessage, wait, actionMove])
        let sequence = SKAction.sequence([halfSequence, halfSequence.reversedAction()])
        
        enemy.runAction(sequence)
    }
    
    // MARK: -
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        let touchLocation = touch.locationInNode(self)
        sceneTouched(touchLocation)
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        let touchLocation = touch.locationInNode(self)
        sceneTouched(touchLocation)
    }
    
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - playableHeight)/2.0
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight)
        super.init(size: size)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}