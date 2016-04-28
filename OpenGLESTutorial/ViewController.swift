//
//  ViewController.swift
//  OpenGLESTutorial
//
//  Created by zhongzhendong on 4/27/16.
//  Copyright © 2016 zhongzhendong. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let openGLView = OpenGLView03(frame:view.bounds)
        self.view.addSubview(openGLView)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

