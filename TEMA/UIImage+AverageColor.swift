//
//  UIImage+AverageColor.swift
//  TEMA
//
//  Created by Paul Paturel on 25/02/2025.
//
import SwiftUI
import UIKit
import CoreImage

extension UIImage {
    func averageColor(in rect: CGRect) -> UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let context = CIContext(options: nil)
        let extentVector = CIVector(cgRect: rect)
        
        guard let filter = CIFilter(name: "CIAreaAverage",
                                    parameters: [kCIInputImageKey: inputImage,
                                                 kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())
        
        let r = CGFloat(bitmap[0]) / 255.0
        let g = CGFloat(bitmap[1]) / 255.0
        let b = CGFloat(bitmap[2]) / 255.0
        let a = CGFloat(bitmap[3]) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    func dynamicTextColor(for image: UIImage) -> Color {
        // On prend le haut 20% de l'image pour calculer la couleur moyenne.
        let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height * 0.2)
        if let avgColor = image.averageColor(in: rect) {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            avgColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            // Formule de luminance standard
            let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
            // Si luminance > 0.5, le fond est clair donc le texte devrait être noir, sinon blanc.
            return luminance > 0.5 ? .black : .white
        } else {
            return .white
        }
    }
}
