//
//  BlurEffect.swift
//  Fokus
//
//  Created by Patrick Lanham on 19.07.25.
//

import Foundation
import SwiftUI

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
