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
    var isZombieInvincible = false
    
    let catMovePointsPerSec: CGFloat = 480.0
    let backgroundMovePointsPerSec: CGFloat = 200.0
    
    let backgroundLayer = SKNode()
    
    var lives = 5
    var gameOver = false
    
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false)
    
    override func didMoveToView(view: SKView) {
        playBackgroundMusic("backgroundMusic.mp3")
        
        backgroundLayer.zPosition = -1
        addChild(backgroundLayer)
        
        backgroundColor = SKColor.whiteColor()
        
        // add background sprite
        for i in 0...1 {
            let background = backgroundNode()
            background.anchorPoint = CGPointZero
            background.position = CGPoint(x: CGFloat(i) * background.size.width, y: 0)
            background.name = "background"
            backgroundLayer.addChild(background)
        }
        
        // add zombie
        zombie.position = CGPointMake(400, 400)
        zombie.zPosition = 100
        backgroundLayer.addChild(zombie)
        
        // add enemy
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([SKAction.runBlock(spawnEnemy),
                               SKAction.waitForDuration(2.0)])))
        
        // add cat
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([SKAction.runBlock(spwanCat),
                               SKAction.waitForDuration(1.0)])))
    }
    
    func backgroundNode() -> SKSpriteNode {
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPointZero
        backgroundNode.name = "background"
        
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPointZero
        background1.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(background1)
        
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPointZero
        background2.position = CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        
        backgroundNode.size = CGSize(
            width: background1.size.width + background2.size.width,
            height: background1.size.height)
        
        return backgroundNode
    }
    
    func moveBackground() {
        let backgroundVelocity = CGPoint(x: -backgroundMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        backgroundLayer.position += amountToMove
        
        backgroundLayer.enumerateChildNodesWithName("background") { node, _ in
            let background = node as SKSpriteNode
            let backgroundScreenPos = self.backgroundLayer.convertPoint(background.position, toNode: self)
            
            if backgroundScreenPos.x <= -background.size.width {
                background.position = CGPoint(
                    x: background.position.x + background.size.width * 2,
                    y: background.position.y)
            }
        }
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
            moveSprite(zombie, velocity: velocity)
            rotateSprite(zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
    
        }
        
        boundsCheckZombie()
        moveTrain()
        moveBackground()
        
        if lives <= 0 && !gameOver {
            gameOver = true
            println("You lose!")
            backgroundMusicPlayer.stop()
            
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
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
        let bottomLeft = backgroundLayer.convertPoint(
            CGPoint(x: 0, y: CGRectGetMinY(playableRect)), fromNode: self)
        let topRight = backgroundLayer.convertPoint(
            CGPoint(x: size.width, y: CGRectGetMaxY(playableRect)),
            fromNode: self)
        
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
        
        let enemeyScreenPos = CGPoint(
            x: size.width + enemy.size.width/2,
            y: CGFloat.random(
                min: CGRectGetMinY(playableRect) + enemy.size.height/2,
                max: CGRectGetMaxY(playableRect) - enemy.size.height/2))
        
        enemy.position = backgroundLayer.convertPoint(enemeyScreenPos, fromNode: self)
        backgroundLayer.addChild(enemy)
        
        let enemyScreenRemovePos = CGPoint(x: -enemy.size.width/2, y: enemeyScreenPos.y)
        let actionMove = SKAction.moveToX(backgroundLayer.convertPoint(enemyScreenRemovePos, fromNode: self).x, duration: 2.0)
        
        let actionRemove = SKAction.removeFromParent()
        enemy.runAction(SKAction.sequence([actionMove, actionRemove]))
    }
    
    // MARK: - Cat
    
    func spwanCat() {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        // randomly position cat inside playable rectangle
        let catScenePos = CGPoint(
            x: CGFloat.random(min: CGRectGetMinX(playableRect), max: CGRectGetMaxX(playableRect)),
            y: CGFloat.random(min: CGRectGetMinY(playableRect), max: CGRectGetMaxY(playableRect)))
        cat.position = backgroundLayer.convertPoint(catScenePos, fromNode: self)
        backgroundLayer.addChild(cat)
        
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
        cat.name = "train"
        cat.removeAllActions()
        cat.setScale(1.0)
        cat.zRotation = 0
        
        let greenAction = SKAction.colorizeWithColor(SKColor.greenColor() , colorBlendFactor: 1, duration: 0.2)
        cat.runAction(greenAction)
        
        runAction(catCollisionSound)
    }
    
    func moveTrain() {
        var trainCount = 0
        var targetPosition = zombie.position
        
        backgroundLayer.enumerateChildNodesWithName("train", usingBlock: { node, _ in
            trainCount++
            if !node.hasActions() {
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.catMovePointsPerSec
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.moveByX(amountToMove.x, y: amountToMove.y, duration: actionDuration)
                node.runAction(moveAction)
            }
            targetPosition = node.position
        })
        
        if trainCount >= 30 && !gameOver {
            gameOver = true
            println("You win!")
            backgroundMusicPlayer.stop()
            
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func loseCats() {
        var loseCount = 0
        backgroundLayer.enumerateChildNodesWithName("train") { node, stop in
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            
            node.name = ""
            node.runAction(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.rotateByAngle(π*4, duration: 1.0),
                        SKAction.moveTo(randomSpot, duration: 1.0),
                        SKAction.scaleTo(0, duration: 1.0)
                    ]),
                SKAction.removeFromParent()
                ]))

                loseCount++
                if loseCount >= 2 {
                    stop.memory = true
                }
            
        }
    }
    
    func zombieHitEnemy(enemy: SKSpriteNode) {
        isZombieInvincible = true
        
        // blink zombie
        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customActionWithDuration(duration, actionBlock: { node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime) % slice
            node.hidden = remainder > slice / 2
        })
        
        let readyToPlayAction = SKAction.runBlock({
            self.zombie.hidden = false
            self.isZombieInvincible = false
        })
        
        let collisionGroup = SKAction.group([blinkAction, enemyCollisionSound])
        
        let action = SKAction.sequence([collisionGroup, readyToPlayAction])
        
        zombie.runAction(action)
        
        loseCats()
        lives--
    }
    
    func checkCollisions() {
        var hitCats: [SKSpriteNode] = []
        backgroundLayer.enumerateChildNodesWithName("cat", usingBlock: { node, _ in
            let cat = node as SKSpriteNode
            if CGRectIntersectsRect(cat.frame, self.zombie.frame) {
                hitCats.append(cat)
            }
        })
        for cat in hitCats {
            zombieHitCat(cat)
        }
        
        if !isZombieInvincible {
            var hitEnemies: [SKSpriteNode] = []
            backgroundLayer.enumerateChildNodesWithName("enemy", usingBlock: { node, _ in
                let enemy = node as SKSpriteNode
                if CGRectIntersectsRect(CGRectInset(node.frame, 20, 20), self.zombie.frame) {
                    hitEnemies.append(enemy)
                }
            })
            for enemy in hitEnemies {
                zombieHitEnemy(enemy)
            }
        }
    }
    
    // MARK: -
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        let touchLocation = touch.locationInNode(backgroundLayer)
        sceneTouched(touchLocation)
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        let touchLocation = touch.locationInNode(backgroundLayer)
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