//
//  Less.swift
//  Git
//
//  Created by Jake Heiser on 8/30/16.
//
//

import Foundation
import SwiftCLI
import Cncurses
import FileKit

class Less {
    
    let readLine: () -> String?
    
    var startIndex = 0
    var lines: [String] = []
    
    init(readLine: @escaping () -> String?) {
        self.readLine = readLine
    }
    
    init(readChunk: @escaping () -> [String]?) {
        var currentChunk: [String]?
        self.readLine = {
            if currentChunk == nil || currentChunk!.isEmpty {
                currentChunk = readChunk()
                if currentChunk == nil || currentChunk!.isEmpty {
                    return nil
                }
            }
            
            return currentChunk!.removeFirst()
        }
    }
    
    private enum MoveDirection {
        case up
        case down
        case none
    }
    
    func go() {
        initscr()
        
        let lineCount = Int(getmaxy(stdscr))
        let textLineCount = lineCount - 1

        for _ in 0 ..< textLineCount {
            let line = readLine() ?? "(EOF)"
            lines.append(line)
        }
        
        noecho()
        cbreak()
        
        // Helpful for debuggin this since can't use print
        // try! (Path.Current + "output.txt").createFile()
        // let out = FileHandle(forWritingAtPath: (Path.Current + "output.txt").rawValue)
        
        while true {
            move(0, 0)
            for i in 0 ..< textLineCount {
                let output = lines[startIndex + i] + "\n"
                addstr(output)
            }
            addstr(":")
            refresh()
            
            let input = getch()
            
            if input == 113 { // q
                break
            }
            
            var moveDirection: MoveDirection = .none
            
            if input == 27 { // Escape -- first of arrow key sequence
                _ = getch()
                let direction = getch()
                if direction == 66 { // Down
                    moveDirection = .down
                } else if direction == 65 { // Up
                    moveDirection = .up
                }
            } else if input == 10 { // New line
                moveDirection = .down
            }
            
            if moveDirection == .down {
                if textLineCount + startIndex == lines.count {
                    if let next = readLine() {
                        lines.append(next)
                        startIndex += 1
                    }
                } else {
                    startIndex += 1
                }
            } else if moveDirection == .up && startIndex > 0{
                startIndex -= 1
            }
        }
        
        endwin()
    }
    
}
