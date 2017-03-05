//
//  SwactorTests.swift
//  SwactorTests
//
//  Created by Tomek on 05.07.2014.
//  Copyright (c) 2014 Tomek Cejner. All rights reserved.
//

import XCTest
import Swactor

class SwactorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    struct CoffeeOrder {
        var name:String
        var expect:XCTestExpectation?
    }
    
    class Barista : Actor {
        var cashier: ActorRef
        
        required init(actorSystem: ActorSystem) {
            cashier = actorSystem.actorOf(actor: Cashier.init(actorSystem: actorSystem))
            super.init(actorSystem: actorSystem)
        }
        
        override func receive(message: Any) {
            switch message {
                case let order as CoffeeOrder :
                    cashier ! Bill(amount: 200, expect:order.expect)
                    NSLog ("I am making coffee \(order.name)")
                    order.expect?.fulfill()
                default:
                    unhandled(message: message)
            }
        }
    }
    
    struct Bill {
        var amount:Int
        var expect:XCTestExpectation?
    }
    
    class Cashier : Actor {

        required init(actorSystem: ActorSystem) {
            super.init(actorSystem: actorSystem)
        }
        
        override func receive(message: Any) {
            switch message {
            case let bill as Bill :
                NSLog("Billing $\(bill.amount)")
                bill.expect?.fulfill()
                
            default:
                unhandled(message: message)
            }
        }
    }
    
    func testBasic() {
        
        let actorSystem = ActorSystem()
        
        let barista: ActorRef = actorSystem.actorOf(
            actor: Barista.init(actorSystem: actorSystem)
        )
        
        barista ! CoffeeOrder(
            name:"Latte",
            expect:expectation(description: "Cashier acted")
        )
        
        waitForExpectations(timeout: 10.0, handler: { (error: Error?) in
            NSLog("Done")
            if let error = error {
                print("There was error \(error.localizedDescription)")
            } else {
                
            }
        })
        
    }
    
    func testActorReuse() {
        let actorSystem = ActorSystem()
        
        let barista1: ActorRef = actorSystem.actorOf(
            actor: Barista.init(actorSystem: actorSystem)
        )
        let barista2: ActorRef = actorSystem.actorOf(
            actor: Barista.init(actorSystem: actorSystem)
        )
        
        XCTAssertTrue(barista1 === barista2, "Should be same instance")
    }
    
    func testDelayedMessage() {
        let actorSystem = ActorSystem()
        
        let cashier: ActorRef = actorSystem.actorOf(
            actor: Cashier.init(actorSystem: actorSystem)
        )
        
        cashier.tell(
            message: Bill(
                amount: 100,
                expect: expectation(description: "Called after two seconds")
            ),
            milliseconds: 2000
        )
        
        waitForExpectations(timeout: 3.0, handler: { error in
            NSLog("Done waiting for delayed message")
        })
        
    }
}
