//
//  AStarPathfinder.swift
//  CatMaze
//
//  Created by Gabriel Hauber on 8/05/2015.
//  Copyright (c) 2015 Razeware LLC. All rights reserved.
//

import Foundation

/** A single step on the computed path; used by the A* pathfinding algorithm */
private class ShortestPathStep: Hashable {
  let position: TileCoord
  var parent: ShortestPathStep?

  var gScore = 0
  var hScore = 0
  var fScore: Int {
    return gScore + hScore
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(position.col.hashValue + position.row.hashValue)
  }
  
  init(position: TileCoord) {
    self.position = position
  }

  func setParent(_ parent: ShortestPathStep, withMoveCost moveCost: Int) {
    // The G score is equal to the parent G score + the cost to move from the parent to it
    self.parent = parent
    self.gScore = parent.gScore + moveCost
  }
}

private func ==(lhs: ShortestPathStep, rhs: ShortestPathStep) -> Bool {
  return lhs.position == rhs.position
}

extension ShortestPathStep: CustomStringConvertible {
  var description: String {
    return "pos=\(position) g=\(gScore) h=\(hScore) f=\(fScore)"
  }
}


protocol PathfinderDataSource: NSObjectProtocol {
  func walkableAdjacentTilesCoordsForTileCoord(_ tileCoord: TileCoord) -> [TileCoord]
  func costToMoveFromTileCoord(_ fromTileCoord: TileCoord, toAdjacentTileCoord toTileCoord: TileCoord) -> Int
}

/** A pathfinder based on the A* algorithm to find the shortest path between two locations */
class AStarPathfinder {

  weak var dataSource: PathfinderDataSource!

  func shortestPathFromTileCoord(_ fromTileCoord: TileCoord, toTileCoord: TileCoord) -> [TileCoord]? {
    var closedSteps = Set<ShortestPathStep>()

    // The open steps list is initialised with the from position
    var openSteps = [ShortestPathStep(position: fromTileCoord)]

    while !openSteps.isEmpty {
      // remove the lowest F cost step from the open list and add it to the closed list
      // Because the list is ordered, the first step is always the one with the lowest F cost
      let currentStep = openSteps.remove(at: 0)
      closedSteps.insert(currentStep)

      // If the current step is the desired tile coordinate, we are done!
      if currentStep.position == toTileCoord {
        return convertStepsToShortestPath(currentStep)
      }

      // Get the adjacent tiles coords of the current step
      let adjacentTiles = dataSource.walkableAdjacentTilesCoordsForTileCoord(currentStep.position)
      for tile in adjacentTiles {
        let step = ShortestPathStep(position: tile)

        // check if the step isn't already in the closed list
        if closedSteps.contains(step) {
          continue // ignore it
        }

        // Compute the cost from the current step to that step
        let moveCost = dataSource.costToMoveFromTileCoord(currentStep.position, toAdjacentTileCoord: step.position)

        // Check if the step is already in the open list
        if let existingIndex = openSteps.firstIndex(of: step) {
          // already in the open list

          // retrieve the old one (which has its scores already computed)
          let step = openSteps[existingIndex]

          // check to see if the G score for that step is lower if we use the current step to get there
          if currentStep.gScore + moveCost < step.gScore {
            // replace the step's existing parent with the current step
            step.setParent(currentStep, withMoveCost: moveCost)

            // Because the G score has changed, the F score may have changed too
            // So to keep the open list ordered we have to remove the step, and re-insert it with
            // the insert function which is preserving the list ordered by F score
            openSteps.remove(at: existingIndex)
            insertStep(step, inOpenSteps: &openSteps)
          }

        } else { // not in the open list, so add it
          // Set the current step as the parent
          step.setParent(currentStep, withMoveCost: moveCost)

          // Compute the H score which is the estimated movement cost to move from that step to the desired tile coordinate
          step.hScore = hScoreFromCoord(step.position, toCoord: toTileCoord)

          // Add it with the function which preserves the list ordered by F score
          insertStep(step, inOpenSteps: &openSteps)
        }
      }

    }

    // no path found
    return nil
  }

  fileprivate func convertStepsToShortestPath(_ lastStep: ShortestPathStep) -> [TileCoord] {
    var shortestPath = [TileCoord]()
    var currentStep = lastStep
    while let parent = currentStep.parent { // if parent is nil, then it is our starting step, so don't include it
      shortestPath.insert(currentStep.position, at: 0)
      currentStep = parent
    }
    return shortestPath
  }

  // Insert a path step in the open steps list
  // The open steps list is ordered from lowest to highest fScore
  fileprivate func insertStep(_ step: ShortestPathStep, inOpenSteps openSteps: inout [ShortestPathStep]) {
    openSteps.append(step)
    openSteps.sorted { $0.fScore <= $1.fScore }
  }

  // Compute the H score from a position to another (from the current position to the final desired position)
  func hScoreFromCoord(_ fromCoord: TileCoord, toCoord: TileCoord) -> Int {
    // Here we use the Manhattan method, which calculates the total number of steps moved horizontally and vertically to reach the final desired step from the current step, ignoring any obstacles that may be in teh way
    return abs(toCoord.col - fromCoord.col) + abs(toCoord.row - fromCoord.row)
  }

}
