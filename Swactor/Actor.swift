//
//  Actor.swift
//  Swactor
//
//  Created by Tomek on 05.07.2014.
//  Copyright (c) 2014 Tomek Cejner. All rights reserved.
//

import Foundation


open class Actor {
    
    var dispatchQueue: DispatchQueue?
    var mailbox: Array<Any>
    var name: String
    var busy: Bool
    let actorSystem: ActorSystem
    
    required public init(actorSystem: ActorSystem) {
        busy = false
        mailbox = Array()
        self.name = String(format: "Actor-%d-%f", arc4random(), Date.timeIntervalSinceReferenceDate)
        self.actorSystem = actorSystem
    }
    
    func put(message: Any) {
        if let dispatchQueue = self.dispatchQueue {
            dispatchQueue.async {
                self.receive(message: message)
            }
        } else {
            // FIXME: send error report
            print("self.dispatchQueue is nil")
        }

    }
    
    func put(message: Any, milliseconds: Int64) {
        let when = DispatchTime.now() + Double(milliseconds * 1000000) / Double(NSEC_PER_SEC)
        
        if let dispatchQueue = self.dispatchQueue {
            dispatchQueue.asyncAfter(deadline: when) {
                self.receive(message: message)
            }
        } else {
            // FIXME: send error report
            print("self.dispatchQueue is nil")
        }
    }
    
    /**
        No-op function which eats unhandled message.
    */
    open func unhandled(message: Any) {
        
    }
    
    // You shall override this function
    open func receive(message: Any) {
        
    }
    
}

open class ActorUI : Actor {
    public required init(actorSystem: ActorSystem) {
        super.init(actorSystem: actorSystem)
    }
}

open class MainThreadActor : Actor {
    
}

open class ActorRef : CustomStringConvertible {
    open let actor: Actor
    var queue: DispatchQueue
    
    open var description: String { get {
        return "<ActorRef name:"+actor.name + ">"
        }
    }
    
    open var name: String {
        get {
            return actor.name
        }
    }
    
    init(actor: Actor, queue: DispatchQueue) {
        self.actor = actor
        self.actor.dispatchQueue = queue
        self.queue = queue
    }
    
    /**
        Send message to actor and return immediately.
    
        :param: message Message object (or structure) to be sent.
    */
    open func tell(message: Any) {
        self.actor.put(message: message)
    }

    /**
        Send message to actor and return immediately. Message will be inserted into dispatch queue
        after given amount of milliseconds.

        :param: message Message object (or structure) to be sent.
        :param: after Delay in milliseconds.

    */
    open func tell(message: Any, milliseconds: Int64) {
        self.actor.put(message: message, milliseconds: milliseconds)
    }
}

open class ActorSystem {
    
    var typeToActorRefDictionary = [String: ActorRef]()

    public init() {
    }
    
    func actorOfInstance(actor: Actor) -> ActorRef {
        switch(actor) {
            case is MainThreadActor:
                return ActorRef(actor: actor, queue: DispatchQueue.main)
            default:
                let name = "root.user." + actor.name
                
                // init(label: String, qos: DispatchQoS = default, attributes: DispatchQueue.Attributes = default, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = default, target: DispatchQueue? = default)
                let queue = DispatchQueue(label: name, attributes: [])
                
                return ActorRef(actor: actor, queue: queue)
            }
    }
    
    /**
        Creates or retrieves cached instance of actor of given class.
    
        :param: actorType Class of actor, should be child of Actor.
    */
    open func actorOf<T: Actor>(actor: T) -> ActorRef {
        let typeName = NSStringFromClass(T.self)
        
        if let actorRef = typeToActorRefDictionary[typeName] {
            return actorRef
        } else {
            let actorRef = actorOfInstance(actor: actor)
            typeToActorRefDictionary[typeName] = actorRef
            return actorRef
        }
    }
}

infix operator  !

public func ! (actorRef:ActorRef, message:Any) -> Void {
    actorRef.tell(message: message)
}


