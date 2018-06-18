//
//  FirstViewController.swift
//  KituraStepTracker
//
//  Created by Joe Anthony Peter Amanse on 5/23/18.
//  Copyright © 2018 Joe Anthony Peter Amanse. All rights reserved.
//

import UIKit
import KituraKit
import CoreData
import HealthKit
import CoreMotion

class UserViewController: UIViewController {

    @IBOutlet weak var userFitcoins: UILabel!
    @IBOutlet weak var userSteps: UILabel!
    @IBOutlet weak var userScrollView: UIScrollView!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userId: UILabel!
    var refreshControl: UIRefreshControl?
    let KituraBackendUrl = "https://anthony-dev.us-south.containers.mybluemix.net"
    
    var pedometer = CMPedometer()
    var currentUser:SavedUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        // Clear labels
        self.userName.text = ""
        self.userId.text = ""
        self.userSteps.text = ""
        self.userFitcoins.text = ""
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.userScrollView.refreshControl = refreshControl
        
        currentUser = (UIApplication.shared.delegate as! AppDelegate).getUserFromLocal()
        self.getCurrentSteps()
    }
    
    func getUserWith(userId: String, enterQueue: @escaping () -> Void, leaveQueue: @escaping () -> Void) {
        enterQueue()
        guard let client = KituraKit(baseURL: self.KituraBackendUrl) else {
            print("Error creating KituraKit client")
            return
        }
        
        client.get("/users/\(userId)") { (user: User?, error: Error?) in
            guard error == nil else {
                print("Error getting leaderboard from Kitura: \(error!)")
                return
            }
            
            guard let user = user else {
                return
            }
            
            print(user)
            self.updateViewWith(userId: user.userId, name: user.name, image: user.image)
            leaveQueue()
        }
    }
    
    func updateViewWith(userId: String, name: String, image: Data) {
        DispatchQueue.main.async {
            self.userId.text = userId
            self.userName.text = name
            self.userImage.image = UIImage(data: image)
            self.userImage.layer.cornerRadius = 75
        }
    }
    
    func getCurrentSteps(enterQueue: @escaping () -> Void = {}, leaveQueue: @escaping () -> Void = {}) {
        enterQueue()
        if let user = self.currentUser {
            pedometer.queryPedometerData(from: user.startDate!, to: Date(), withHandler: { (pedometerData, error) in
                print(pedometerData)
                leaveQueue()
            })
        }
    }
    
    func startUpdatingSteps(_ group: DispatchGroup) {
        group.enter()
        
        // test async
        //TODO: replace with real pedometer
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
            group.leave()
        }
        print("start updates")
    }
    
    // just a test for refreshing
    @objc func refresh() {
        if let user = self.currentUser {
            // refresh data
            
            let group = DispatchGroup()
            
            getUserWith(userId: user.userId!, enterQueue: group.enter, leaveQueue: group.leave)
            getCurrentSteps(enterQueue: group.enter, leaveQueue: group.leave)
            startUpdatingSteps(group)
            
            group.notify(queue: .main) {
                DispatchQueue.main.async {
                    print("done")
                    if (self.refreshControl?.isRefreshing)! {
                        self.refreshControl?.endRefreshing()
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

