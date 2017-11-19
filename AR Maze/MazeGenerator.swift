//
//  File.swift
//  AR Maze
//
//  Created by William Leung on 18/11/17.
//  Copyright © 2017 Wai Kiet William Leung. All rights reserved.
//

import Foundation

extension Array {
    mutating func swap(_ index1:Int, _ index2:Int) {
        let temp = self[index1]
        self[index1] = self[index2]
        self[index2] = temp
    }
    
    mutating func shuffle() {
        for _ in 0..<self.count {
            let index1 = Int(arc4random()) % self.count
            let index2 = Int(arc4random()) % self.count
            self.swap(index1, index2)
        }
    }
}

enum Direction:Int {
    case north = 1
    case south = 2
    case east = 4
    case west = 8
    
    static var allDirections:[Direction] {
        return [Direction.north, Direction.south, Direction.east, Direction.west]
    }
    
    var opposite:Direction {
        switch self {
        case .north:
            return .south
        case .south:
            return .north
        case .east:
            return .west
        case .west:
            return .east
        }
    }
    
    var diff:(Int, Int) {
        switch self {
        case .north:
            return (0, -1)
        case .south:
            return (0, 1)
        case .east:
            return (1, 0)
        case .west:
            return (-1, 0)
        }
    }
    
    var char:String {
        switch self {
        case .north:
            return "N"
        case .south:
            return "S"
        case .east:
            return "E"
        case .west:
            return "W"
        }
    }
    
}

class MazeGenerator {
    let width:Int
    let length:Int
    var maze:[[Int]]
    
    init(_ width:Int, _ length:Int) {
        self.width  = width
        self.length = length
        let column = [Int](repeating: 0, count: length)
        self.maze = [[Int]](repeating: column, count: width)
        generateMaze(0, 0)
    }
    
    private func generateMaze(_ cx:Int, _ cy:Int) {
        var directions = Direction.allDirections
        directions.shuffle()
        for direction in directions {
            let (dx, dy) = direction.diff
            let nx = cx + dx
            let ny = cy + dy
            if inBounds(nx, ny) && maze[nx][ny] == 0 {
                maze[cx][cy] |= direction.rawValue
                maze[nx][ny] |= direction.opposite.rawValue
                generateMaze(nx, ny)
            }
        }
    }
    
    private func inBounds(_ testWidth:Int, _ testLength:Int) -> Bool {
        return inBounds(value:testWidth, upper:self.width) && inBounds(value:testLength, upper:self.length)
    }
    
    private func inBounds(value:Int, upper:Int) -> Bool {
        return (value >= 0) && (value < upper)
    }
    
    func displayInts() {
        for j in 0..<length {
            var line = ""
            for i in 0..<width {
                line += String(maze[i][j]) + "\t"
            }
            print(line)
        }
    }
    
    func displayDirections() {
        for j in 0..<length {
            var line = ""
            for i in 0..<width {
                line += getDirectionsAsString(maze[i][j]) + "\t"
            }
            print(line)
        }
    }
    
    private func getDirectionsAsString(_ value:Int) -> String {
        var line = ""
        for direction in Direction.allDirections {
            if (value & direction.rawValue) != 0 {
                line += direction.char
            }
        }
        return line
    }
}

