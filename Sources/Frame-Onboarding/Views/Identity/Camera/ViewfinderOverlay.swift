//
//  Untitled.swift
//  Frame-iOS
//
//  Created by Eric Townsend on 12/15/25.
//

import SwiftUI

struct ViewfinderOverlay: View {
    let holeSize = CGSize(width: 330, height: 400)
    var overlayOpacity: Double = 0.75
    var strokeWidth: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            let holeRect = CGRect(
                x: (geo.size.width - holeSize.width) / 2,
                y: (geo.size.height - holeSize.height) / 2,
                width: holeSize.width,
                height: holeSize.height
            )

            ZStack {
                // Black overlay with a transparent oval cut-out
                OvalHoleShape(holeRect: holeRect)
                    .fill(.black.opacity(overlayOpacity), style: FillStyle(eoFill: true))
                    .ignoresSafeArea()

                // Optional: border around the oval
                Ellipse()
                    .path(in: holeRect)
                    .stroke(.white.opacity(0.95), lineWidth: strokeWidth)
                
                // Optional: corner markers (looks like a scanner)
                CornerMarkers(rect: holeRect, cornerRadius: 200.0)
                    .stroke(.white.opacity(0.95), lineWidth: strokeWidth)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct OvalHoleShape: Shape {
    let holeRect: CGRect

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRect(rect) // full screen

        // the “hole”
        p.addPath(Ellipse().path(in: holeRect))
        return p
    }
}

private struct CornerMarkers: Shape {
    let rect: CGRect
    let cornerRadius: CGFloat
    var markerLength: CGFloat = 28

    func path(in _: CGRect) -> Path {
        var p = Path()

        // Four corners as short L-shapes
        let tl = CGPoint(x: rect.minX, y: rect.minY)
        let tr = CGPoint(x: rect.maxX, y: rect.minY)
        let bl = CGPoint(x: rect.minX, y: rect.maxY)
        let br = CGPoint(x: rect.maxX, y: rect.maxY)

        // Top-left
        p.move(to: CGPoint(x: tl.x + cornerRadius, y: tl.y))
        p.addLine(to: CGPoint(x: tl.x + cornerRadius + markerLength, y: tl.y))
        p.move(to: CGPoint(x: tl.x, y: tl.y + cornerRadius))
        p.addLine(to: CGPoint(x: tl.x, y: tl.y + cornerRadius + markerLength))

        // Top-right
        p.move(to: CGPoint(x: tr.x - cornerRadius, y: tr.y))
        p.addLine(to: CGPoint(x: tr.x - cornerRadius - markerLength, y: tr.y))
        p.move(to: CGPoint(x: tr.x, y: tr.y + cornerRadius))
        p.addLine(to: CGPoint(x: tr.x, y: tr.y + cornerRadius + markerLength))

        // Bottom-left
        p.move(to: CGPoint(x: bl.x + cornerRadius, y: bl.y))
        p.addLine(to: CGPoint(x: bl.x + cornerRadius + markerLength, y: bl.y))
        p.move(to: CGPoint(x: bl.x, y: bl.y - cornerRadius))
        p.addLine(to: CGPoint(x: bl.x, y: bl.y - cornerRadius - markerLength))

        // Bottom-right
        p.move(to: CGPoint(x: br.x - cornerRadius, y: br.y))
        p.addLine(to: CGPoint(x: br.x - cornerRadius - markerLength, y: br.y))
        p.move(to: CGPoint(x: br.x, y: br.y - cornerRadius))
        p.addLine(to: CGPoint(x: br.x, y: br.y - cornerRadius - markerLength))

        return p
    }
}
