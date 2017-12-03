//
//  FinishScreenViewController.swift
//  AR Maze
//
//  Created by Scott Hodnefield on 12/3/17.
//  Copyright © 2017 Wai Kiet William Leung. All rights reserved.
//

import UIKit

class FinishScreenViewController: UIViewController {
    
    
    @IBAction func returnToMainButton(_ sender: Any) {
        performSegue(withIdentifier: "backToMainSegue", sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
