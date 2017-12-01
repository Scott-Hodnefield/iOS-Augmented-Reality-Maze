//
//  PhysicsCategory.swift
//  AR Maze
//
//  Created by William Leung on 29/11/17.
//  Copyright © 2017 Wai Kiet William Leung. All rights reserved.
//

import Foundation

struct PhysicsCategory {
    static let None: Int = 0
    static let Camera: Int = 1 << 0
    static let WallOrPillar: Int = 1 << 1
}
