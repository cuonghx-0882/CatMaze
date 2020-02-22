//
//  Cat.swift
//  CatMaze
//
//  Created by Gabriel Hauber on 29/04/2015.
//  Copyright (c) 2015 Razeware LLC. All rights reserved.
//

import Foundation
import SpriteKit


extension SKAction {
  class func animate(_ name: String, inDirection direction: String, forFrameCount numFrames: Int, timePerFrame sec: TimeInterval) -> SKAction {
    var animationFrames = [SKTexture]()
    for frameNum in 1...numFrames {
      animationFrames.append(SKTexture(imageNamed: "\(name)\(direction)\(frameNum)"))
    }
    return SKAction.animate(with: animationFrames, timePerFrame: sec)
  }
}


class Cat: SKSpriteNode, PathfinderDataSource {

  var numBones = 0
  weak var gameScene: GameScene!

  let pathfinder = AStarPathfinder()
  var shortestPath: [TileCoord]?

  // keep track of current action so we can cancel it if the user wants the cat
  // to go somewhere new when it is already following a path
  fileprivate var currentStepAction: SKAction?

  // new destination for the cat after it has finished the current step action
  fileprivate var pendingMove: TileCoord?

  // pre-load the sound resources
  let hitWallSound = SKAction.playSoundFileNamed("hitWall.wav", waitForCompletion: false)
  let pickupBoneSound = SKAction.playSoundFileNamed("pickup.wav", waitForCompletion: false)
  let catAttackSound = SKAction.playSoundFileNamed("catAttack.wav", waitForCompletion: false)
  let stepSound = SKAction.playSoundFileNamed("step.wav", waitForCompletion: false)

  // set up the cat walking animations in all four cardinal directions
  fileprivate let facingForwardAnimation = SKAction.animate("Cat", inDirection: "Down", forFrameCount: 2, timePerFrame: 0.1)
  fileprivate let facingBackAnimation = SKAction.animate("Cat", inDirection: "Up", forFrameCount: 2, timePerFrame: 0.1)
  fileprivate let facingLeftAnimation = SKAction.animate("Cat", inDirection: "Left", forFrameCount: 2, timePerFrame: 0.1)
  fileprivate let facingRightAnimation = SKAction.animate("Cat", inDirection: "Right", forFrameCount: 2, timePerFrame: 0.1)


  // MARK: Initialisation

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder) is not used in this app")
  }

  init() {
    let texture = SKTexture(imageNamed: "CatDown1")
    super.init(texture: texture, color: .clear, size: texture.size())
    pathfinder.dataSource = self
  }

  fileprivate func runAnimation(_ animation: SKAction, withKey key: String) {
    // Sprite Kit will automatically remove any existing animation that matches the key we give
    run(SKAction.repeatForever(animation), withKey: key)
  }


  // MARK: Actions

  func moveInDirection(_ direction: Direction) {
    let currentTileCoord = gameScene.tileMap.tileCoordForPosition(position)
    let desiredTileCoord: TileCoord

    switch direction {
    case .up:
      desiredTileCoord = currentTileCoord.top
      runAnimation(facingBackAnimation, withKey: "catWalk")
    case .down:
      desiredTileCoord = currentTileCoord.bottom
      runAnimation(facingForwardAnimation, withKey: "catWalk")
    case .left:
      desiredTileCoord = currentTileCoord.left
      runAnimation(facingLeftAnimation, withKey: "catWalk")
    case .right:
      desiredTileCoord = currentTileCoord.right
      runAnimation(facingRightAnimation, withKey: "catWalk")
    }

    moveTo(desiredTileCoord)
  }

  func moveToward(_ target: CGPoint) {
    let toTileCoord = gameScene.tileMap.tileCoordForPosition(target)
    moveTo(toTileCoord)
  }

  func moveTo(_ toTileCoord: TileCoord) {
    // If the cat is currently following a path, then we will want to record
    // this move as a pending move, which we can check when the current step
    // action is completed
    if currentStepAction != nil {
      pendingMove = toTileCoord
      return
    }

    // Get the current and desired tile coordinates
    let fromTileCoord = gameScene.tileMap.tileCoordForPosition(position)

    // Check that we are actually moving somewhere ;-)
    if fromTileCoord == toTileCoord {
      print("You're already there! :P")
      return
    }

    // Must check that the desired location is walkable
    if !gameScene.isWalkableTileForTileCoord(toTileCoord) {
      run(hitWallSound)
      return
    }

//    println("Finding shortest path from \(fromTileCoord) to \(toTileCoord)")
    shortestPath = pathfinder.shortestPathFromTileCoord(fromTileCoord, toTileCoord: toTileCoord)
    if let shortestPath = shortestPath {
      for tileCoord in shortestPath {
        print("Step: \(tileCoord)")
      }
      popStepAndAnimate()
    }
  }

  func popStepAndAnimate() {
    // finished with a step; first much check if the user has changed their
    // mind about where the cat should go?
    currentStepAction = nil
    if let newMoveTarget = pendingMove {
      pendingMove = nil
      shortestPath = nil
      moveTo(newMoveTarget)
      return
    }

    // check if we are done moving; if so, change cat state to the resting state
    if shortestPath == nil || shortestPath!.isEmpty {
      // done moving, so stop animating and reset to "rest" state (facing down)
      removeAction(forKey: "catWalk")
      texture = SKTexture(imageNamed: "CatDown1")
      return
    }

    // get the next step to move to and remove it from the shortestPath
    let nextTileCoord = shortestPath!.remove(at: 0)

    // determine the direction the cat is facing in order to animate it appropriately
    let currentTileCoord = gameScene.tileMap.tileCoordForPosition(position)

    // make sure the cat is facing in the right direction for its movement
    let diff = nextTileCoord - currentTileCoord
    if abs(diff.col) > abs(diff.row) {
      if diff.col > 0 {
        runAnimation(facingRightAnimation, withKey: "catWalk")
      } else {
        runAnimation(facingLeftAnimation, withKey: "catWalk")
      }
    } else {
      if diff.row > 0 {
        runAnimation(facingForwardAnimation, withKey: "catWalk")
      } else {
        runAnimation(facingBackAnimation, withKey: "catWalk")
      }
    }

    currentStepAction = SKAction.move(to: gameScene.tileMap.positionForTileCoord(nextTileCoord), duration: 0.4)
    run(currentStepAction!, completion: {
      let gameOver = self.updateState()
      if !gameOver {
        self.popStepAndAnimate()
      }
    })
  }

  /** Updates the cat's state for the current position. Returns <code>true</code> if the game ends */
  fileprivate func updateState() -> Bool {
    let currentTileCoord = gameScene.tileMap.tileCoordForPosition(position)

    if gameScene.isBoneAtTileCoord(currentTileCoord) {
      numBones += 1
      gameScene.updateBoneCount(numBones)
      gameScene.removeObjectAtTileCoord(currentTileCoord)
      run(pickupBoneSound)

    } else if gameScene.isDogAtTileCoord(currentTileCoord) {
      if numBones == 0 {
        gameScene.loseGame()
        return true

      } else {
        numBones -= 1
        gameScene.updateBoneCount(numBones)
        gameScene.removeObjectAtTileCoord(currentTileCoord)
        run(catAttackSound)
      }

    } else if gameScene.isExitAtTileCoord(currentTileCoord) {
      gameScene.winGame()
      return true

    } else {
      run(stepSound)
    }
    return false
  }

  func walkableAdjacentTilesCoordsForTileCoord(_ tileCoord: TileCoord) -> [TileCoord] {
    let canMoveUp = gameScene.isWalkableTileForTileCoord(tileCoord.top)
    let canMoveLeft = gameScene.isWalkableTileForTileCoord(tileCoord.left)
    let canMoveDown = gameScene.isWalkableTileForTileCoord(tileCoord.bottom)
    let canMoveRight = gameScene.isWalkableTileForTileCoord(tileCoord.right)

    var walkableCoords = [TileCoord]()

    if canMoveUp {
      walkableCoords.append(tileCoord.top)
    }
    if canMoveLeft {
      walkableCoords.append(tileCoord.left)
    }
    if canMoveDown {
      walkableCoords.append(tileCoord.bottom)
    }
    if canMoveRight {
      walkableCoords.append(tileCoord.right)
    }

    // now the diagonals
    if canMoveUp && canMoveLeft && gameScene.isWalkableTileForTileCoord(tileCoord.topLeft) {
      walkableCoords.append(tileCoord.topLeft)
    }
    if canMoveDown && canMoveLeft && gameScene.isWalkableTileForTileCoord(tileCoord.bottomLeft) {
      walkableCoords.append(tileCoord.bottomLeft)
    }
    if canMoveUp && canMoveRight && gameScene.isWalkableTileForTileCoord(tileCoord.topRight) {
      walkableCoords.append(tileCoord.topRight)
    }
    if canMoveDown && canMoveRight && gameScene.isWalkableTileForTileCoord(tileCoord.bottomRight) {
      walkableCoords.append(tileCoord.bottomRight)
    }

    return walkableCoords
  }

  func costToMoveFromTileCoord(_ fromTileCoord: TileCoord, toAdjacentTileCoord toTileCoord: TileCoord) -> Int {
    let baseCost = (fromTileCoord.col != toTileCoord.col) && (fromTileCoord.row != toTileCoord.row) ? 14 : 10
    return baseCost * (gameScene.isDogAtTileCoord(toTileCoord) ? 10 : 1)
  }

}

// Allow expressions such as let diff = point1 - point2
func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
  return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}
