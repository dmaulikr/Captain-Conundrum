//
//  JoystickNode.swift
//  DungeonGame
//
//  Created by Ishawn Gullapalli on 7/11/17.
//  Copyright © 2017 Ishawn Gullapalli. All rights reserved.
//

import SpriteKit

class JoystickNode: SKNode {
    
    var velocity: CGFloat = 0
    
    var radius: CGFloat!
    var mainColor: UIColor!
    var backgroundColor: UIColor!
    
    var backgroundCircle: SKShapeNode!
    var outerCircle: SKShapeNode!
    var innerCircle: SKShapeNode!
    
    let fixedDelta = 1.0 / 60.0
    var timeSinceTouch: CFTimeInterval = 0
    
    init(radius: CGFloat, backgroundColor: UIColor, mainColor: UIColor) {
        super.init()
        self.radius = radius
        self.mainColor = mainColor
        self.backgroundColor = backgroundColor
        createJoystick()
        isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createJoystick() {
        outerCircle = SKShapeNode(circleOfRadius: radius)
        outerCircle.zPosition = 1000
        innerCircle = SKShapeNode(circleOfRadius: radius * 0.6)
        innerCircle.zPosition = 1001
        outerCircle.fillColor = backgroundColor
        innerCircle.fillColor = mainColor
        outerCircle.addChild(innerCircle)
        addChild(outerCircle)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        
        timeSinceTouch = 0
        
        innerCircle.position = location
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        let distance = distanceBetweenPoints(a: outerCircle.position, b: location)
        
        timeSinceTouch = 0
        
        velocity = distance / radius <= radius ? distance / radius : 1
        innerCircle.position = distance <= radius ? location : CGPoint(x: location.x / distance * radius, y: location.y / distance * radius)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        innerCircle.run(SKAction.move(to: CGPoint(x: 0, y: 0), duration: 0.1))
    }
    
    func update(_ currentTime: TimeInterval) {
        timeSinceTouch += fixedDelta
        if timeSinceTouch >= 3 && timeSinceTouch <= 3 + fixedDelta{
            // make translucent
            innerCircle.run(SKAction.fadeAlpha(by: -0.2 /* (mainColor.cgColor.components?[3])!*/, duration: 1))
            outerCircle.run(SKAction.fadeAlpha(by: -0.2 /* (backgroundColor.cgColor.components?[3])!*/, duration: 1))
        } else if timeSinceTouch < 3 {
            // make opaque
            innerCircle.alpha = (mainColor.cgColor.components?[3])!
            outerCircle.alpha = (backgroundColor.cgColor.components?[3])!
        }
    }
    
    func moveRight(speed: CGFloat) -> CGFloat {
        if innerCircle.position.x > outerCircle.position.x + radius / 3 {
            return speed * velocity
        }
        return 0
    }
    
    func moveLeft(speed: CGFloat) -> CGFloat {
        if innerCircle.position.x < outerCircle.position.x - radius / 3 {
            return speed * velocity
        }
        return 0
    }
    
    func moveUp(speed: CGFloat) -> CGFloat {
        if innerCircle.position.y > outerCircle.position.y + radius / 3 {
            return speed * velocity
        }
        return 0
    }
    
    func moveDown(speed: CGFloat) -> CGFloat {
        if innerCircle.position.y < outerCircle.position.y - radius / 3 {
            return speed * velocity
        }
        return 0
    }
    
}

func clamp<T: Comparable>(value: T, lower: T, upper: T) -> T {
    return min(max(value, lower), upper)
}

func distanceBetweenPoints(a: CGPoint, b: CGPoint) -> CGFloat {
    return sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2))
}
