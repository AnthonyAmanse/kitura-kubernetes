//
//  FirstViewController.swift
//  KituraStepTracker
//
//  Created by Joe Anthony Peter Amanse on 5/23/18.
//  Copyright © 2018 Joe Anthony Peter Amanse. All rights reserved.
//

import UIKit

class UserViewController: UIViewController {

    @IBOutlet weak var userScrollView: UIScrollView!
    @IBOutlet weak var userStack: UIStackView!
    var refreshControl: UIRefreshControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        userScrollView.alwaysBounceVertical = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

