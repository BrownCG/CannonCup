//
//  ViewController.swift
//  CannonCup
//
//  Created by C Brown on 6/23/20.
//  Copyright © 2020 C Brown. All rights reserved.
//

import UIKit
import ARKit
import Each

enum BitMaskCategory: Int {
    case ball = 2
    case target = 3
}

class ViewController: UIViewController, SCNPhysicsContactDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var cannonPlaced: Bool {
        return self.sceneView.scene.rootNode.childNode(withName: "cannon", recursively: false) != nil
    }
    var power: Float = 1.0
    var timer = Each(0.08).seconds
    var Target: SCNNode?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,
            ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.scene.physicsWorld.contactDelegate = self
        self.sceneView.session.run(configuration)
    }
    
    @IBAction func resetCannon(_ sender: Any) {
        restartSession()
        let barrel = SCNNode(geometry: SCNTube(innerRadius: 0.02, outerRadius: 0.03, height: 0.08))
        let node = SCNNode()
        node.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.1/3)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        node.geometry?.firstMaterial?.specular.contents = UIColor.white
        node.name = "cannon"
        node.position = SCNVector3(0,0,-0.3)
        barrel.position = SCNVector3(0.0, 0.03, -0.02)
        barrel.eulerAngles = SCNVector3(Float(-45.degreesToRadians),0,0)
        self.sceneView.scene.rootNode.addChildNode(node)
        node.addChildNode(barrel)
        
    }
    
    @IBAction func randCup(_ sender: Any) {
        let node = SCNNode()
        node.geometry = SCNTube(innerRadius: 0.025, outerRadius: 0.03, height: 0.06)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        node.geometry?.firstMaterial?.specular.contents = UIColor.white
        let x = randomNumbers(firstNum: -0.3, secondNum: 0.3)
        let y = randomNumbers(firstNum: 0.0, secondNum: 0.3)
        let z = randomNumbers(firstNum: -1.5, secondNum: -2.5)
        let lip = SCNNode(geometry: SCNTorus(ringRadius: 0.03, pipeRadius: 0.005))
        lip.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        lip.geometry?.firstMaterial?.specular.contents = UIColor.white
        lip.position = SCNVector3(0.0, 0.035, 0.0)
        node.position = SCNVector3(x,y,z)
        let bottom = SCNNode(geometry: SCNCylinder(radius: 0.028, height: 0.01))
        bottom.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        bottom.position = SCNVector3(0,-0.03,0)
        let target = SCNNode(geometry: SCNSphere(radius: 0.01))
        target.position = SCNVector3(0.0, 0.04, 0.0)
        target.name = "target"
        target.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        target.physicsBody?.categoryBitMask = BitMaskCategory.target.rawValue
        target.physicsBody?.contactTestBitMask = BitMaskCategory.ball.rawValue
        node.addChildNode(target)
        node.addChildNode(lip)
        node.addChildNode(bottom)
        node.name = "cup"
        node.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: lip))
        self.sceneView.scene.rootNode.addChildNode(node)
    }
    
    
    @IBAction func rotateCannon(_ sender: UIStepper) {
        self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
            if node.name == "cannon"{
                let action = SCNAction.rotateTo(x: 0, y: CGFloat(-(Int(sender.value)).degreesToRadians), z: 0, duration: 0.3)
                node.runAction(action)
            }
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.cannonPlaced == true {
            timer.perform(closure: { () -> NextStep in
                self.power += 1
                return .continue
            })
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.cannonPlaced == true {
            self.timer.stop()
            self.shootBall()
        }
        self.power = 1.0
    }
    
    func shootBall () {
        let ball = SCNNode(geometry: SCNSphere(radius:0.007))
        ball.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        ball.position = SCNVector3(0.0, 0.05, -0.3)
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node:ball))
        ball.physicsBody = body
        ball.physicsBody?.categoryBitMask = BitMaskCategory.ball.rawValue
        ball.physicsBody?.contactTestBitMask = BitMaskCategory.target.rawValue
        guard let cannon = self.sceneView.scene.rootNode.childNode(withName: "cannon", recursively: false) else { return }
        print(cannon.rotation)
        let rotationValue = -Float((cannon.rotation.y * cannon.rotation.w) * 3)
        ball.physicsBody?.applyForce(SCNVector3(rotationValue, (0.085 * power), (-1.0 - (0.15 * power))), asImpulse: true)
        self.sceneView.scene.rootNode.addChildNode(ball)
    }
    
    func restartSession() {
        self.sceneView.session.pause()
        self.sceneView.scene.rootNode.enumerateChildNodes {
            (node, _) in node.removeFromParentNode()
        }
        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func randomNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat {
     return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        print("hit detected")
        if contact.nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
            Target = contact.nodeA
        } else if contact.nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
            Target = contact.nodeB
        }
        contact.nodeB.removeFromParentNode()
        contact.nodeA.removeFromParentNode()
    }
}

extension Int {
    
    var degreesToRadians: Double { return Double(self) * .pi/180}

}
