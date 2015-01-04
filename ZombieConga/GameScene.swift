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
    let zombieAnimation: SKAction
    
    var lastUpdateTime: NSTimeInterval = 0
    var dt: NSTimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0
    let zombieRotateRadiansPerSec: CGFloat = 4.0 * π
    var velocity = CGPointZero
    
    var lastTouchLocation: CGPoint?
    
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
        
        // add enemy
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([SKAction.runBlock(spawnEnemy),
                               SKAction.waitForDuration(2.0)])))
        
        // add cat
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([SKAction.runBlock(spwanCat),
                               SKAction.waitForDuration(1.0)])))
    }
    
    override func update(currentTime: NSTimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        if let lastTouchLocation = lastTouchLocation {
            let touchDistance = (lastTouchLocation - zombie.position).length()
            if touchDistance < zombieMovePointsPerSec * CGFloat(dt) {
                zombie.position = lastTouchLocation
                velocity = CGPointZero
                stopZombieAnimation()
            } else {
                moveSprite(zombie, velocity: velocity)
                rotateSprite(zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
            }
        }
        
        boundsCheckZombie()
    }
    
    override func didEvaluateActions() {
        checkCollisions()
    }
    
    // MARK: - Zombie
    
    func startZombieAnimation() {
        if zombie.actionForKey("animation") == nil {
            zombie.runAction(
                SKAction.repeatActionForever(zombieAnimation),
                withKey: "animation")
        }
    }
    
    func stopZombieAnimation() {
        zombie.removeActionForKey("animation")
    }
    
    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = velocity * CGFloat(dt)
        sprite.position += amountToMove
    }
    
    func moveZombieTowardLocation(location: CGPoint) {
        startZombieAnimation()
        
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
        lastTouchLocation = touchLocation
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
        enemy.name = "enemy"
        enemy.position = CGPoint(
            x: size.width + enemy.size.width/2,
            y: CGFloat.random(
                min: CGRectGetMinY(playableRect) + enemy.size.height/2,
                max: CGRectGetMaxY(playableRect) - enemy.size.height/2))
        addChild(enemy)
        
        let actionMove = SKAction.moveToX(-enemy.size.width/2, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        enemy.runAction(SKAction.sequence([actionMove, actionRemove]))
    }
    
    // MARK: - Cat
    
    func spwanCat() {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        // randomly position cat inside playable rectangle
        cat.position = CGPoint(
            x: CGFloat.random(min: CGRectGetMinX(playableRect), max: CGRectGetMaxX(playableRect)),
            y: CGFloat.random(min: CGRectGetMinY(playableRect), max: CGRectGetMaxY(playableRect)))
        cat.setScale(0)
        addChild(cat)
        
        let appear = SKAction.scaleTo(1.0, duration: 0.5)
        
        // back and forth wiggle
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotateByAngle(π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversedAction()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        
        let scaleUp = SKAction.scaleBy(1.2, duration: 0.25)
        let scaleDown = scaleUp.reversedAction()
        let fullScale = SKAction.sequence(
            [scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeatAction(group, count: 10)
        
        let disappear = SKAction.scaleTo(0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        
        cat.runAction(SKAction.sequence(actions))
    }
    
    // MARK: - Collision
    
    func zombieHitCat(cat: SKSpriteNode) {
        cat.removeFromParent()
    }
    
    func zombieHitEnemy(enemy: SKSpriteNode) {
        enemy.removeFromParent()
    }
    
    func checkCollisions() {
        var hitCats: [SKSpriteNode] = []
        enumerateChildNodesWithName("cat", usingBlock: { node, _ in
            let cat = node as SKSpriteNode
            if CGRectIntersectsRect(cat.frame, self.zombie.frame) {
                hitCats.append(cat)
            }
        })
        for cat in hitCats {
            zombieHitCat(cat)
        }
        
        var hitEnemies: [SKSpriteNode] = []
        enumerateChildNodesWithName("enemy", usingBlock: { node, _ in
            let enemy = node as SKSpriteNode
            if CGRectIntersectsRect(CGRectInset(node.frame, 20, 20), self.zombie.frame) {
                hitEnemies.append(enemy)
            }
        })
        for enemy in hitEnemies {
            zombieHitEnemy(enemy)
        }
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
        
        var textures: [SKTexture] = []
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        
        textures.append(textures[2])
        textures.append(textures[1])
        
        zombieAnimation = SKAction.repeatActionForever(
            SKAction.animateWithTextures(textures, timePerFrame: 0.1))
        
        super.init(size: size)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}