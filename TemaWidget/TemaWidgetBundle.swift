//
//  TemaWidgetBundle.swift
//  TemaWidget
//
//  Created by Paul Paturel on 24/03/2025.
//

import WidgetKit
import SwiftUI

@main
struct TemaWidgetBundle: WidgetBundle {
    var body: some Widget {
        TemaWidget()
        TemaWidgetControl()
        TemaWidgetLiveActivity()
    }
}
