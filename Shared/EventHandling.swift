//
//  EventHandling.swift
//  Cat Maze
//
//  Created by Gabriel Hauber on 22/04/2015.
//  Copyright (c) 2015 Razeware LLC. All rights reserved.
//

import SpriteKit

// MARK: - cross-platform object type aliases

#if os(iOS)
typealias CCUIEvent = UITouch
typealias CCTapOrClickGestureRecognizer = UITapGestureRecognizer
#else
typealias CCUIEvent = NSEvent
typealias CCTapOrClickGestureRecognizer = NSClickGestureRecognizer
import Carbon // for the OS X virtual key codes!
#endif

enum Direction {
  case up, down, left, right
}
// ideally this would be a struct, but swiftc does not allow overriding functions declared in extensions
// unless the declaration is fully Objective-C compatible
/** abstracting events from keyboards, etc */
class ControllerEvent {
  let direction: Direction
  init(direction: Direction) {
    self.direction = direction
  }
}

extension SKNode {

  #if os(iOS)

  // MARK: - iOS Touch handling

  open func touchesBegan(_ touches: Set<NSObject>, with event: UIEvent)  {
    userInteractionBegan(touches.first as! UITouch)
  }

  open func touchesMoved(_ touches: Set<NSObject>, with event: UIEvent)  {
    userInteractionContinued(touches.first as! UITouch)
  }

  open func touchesEnded(_ touches: Set<NSObject>, with event: UIEvent) {
    userInteractionEnded(touches.first as! UITouch)
  }

  open func touchesCancelled(_ touches: Set<NSObject>, with event: UIEvent) {
    userInteractionCancelled(touches.first as! UITouch)
  }

  #else

  // MARK: - OS X mouse event handling

  override public func mouseDown(event: NSEvent) {
    userInteractionBegan(event)
  }

  override public func mouseDragged(event: NSEvent) {
    userInteractionContinued(event)
  }

  override public func mouseUp(event: NSEvent) {
    userInteractionEnded(event)
  }

  public override func keyDown(theEvent: NSEvent) {
    switch Int(theEvent.keyCode) {
    case kVK_UpArrow: controllerEvent(ControllerEvent(direction: .Up))
    case kVK_LeftArrow: controllerEvent(ControllerEvent(direction: .Left))
    case kVK_RightArrow: controllerEvent(ControllerEvent(direction: .Right))
    case kVK_DownArrow: controllerEvent(ControllerEvent(direction: .Down))
    default: break // nothing
    }
  }

  #endif

  // MARK: - Cross-platform event handling

  func userInteractionBegan(_ event: CCUIEvent) {
  }

  func userInteractionContinued(_ event: CCUIEvent) {
  }

  func userInteractionEnded(_ event: CCUIEvent) {
  }

  func userInteractionCancelled(_ event: CCUIEvent) {
  }

  func controllerEvent(_ event: ControllerEvent) {
  }

}
