//
//  Synchronize.swift
//  ebikeStory
//
//  Created by Sangchul Lee on 3/5/17.
//  Copyright © 2017 sangclee. All rights reserved.
//

import Foundation

func synchronize(lock: AnyObject, closure: () -> Void) {
    
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}
