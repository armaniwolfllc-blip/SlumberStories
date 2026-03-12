//
//  Item.swift
//  SlumberStories
//
//  Created by Armani Wattie on 3/12/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
