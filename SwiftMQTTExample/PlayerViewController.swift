//
//  PlayerViewController.swift
//  PiWatch
//
//  Created by Priyanka Gopakumar on 14/11/2016.
//  Copyright © 2016 Priyanka. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class PlayerViewController: UIViewController {
    
    override func viewDidLoad() {
        let videoURL = NSURL(string:"https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")
        let player = AVPlayer(URL: videoURL!)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        self.presentViewController(playerViewController, animated: true) { () -> Void in
               playerViewController.player!.play()
        }
    }

}
