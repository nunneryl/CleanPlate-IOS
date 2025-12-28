// In file: MapSnapshotView.swift

import SwiftUI
import MapKit
import os

struct MapSnapshotView: View {
    let coordinate: CLLocationCoordinate2D

    @State private var snapshotImage: UIImage? = nil
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "CleanPlate", category: "MapSnapshot")

    var body: some View {
        Group {
            if let image = snapshotImage {
                Image(uiImage: image)
                   .resizable()
                   .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    Color(.systemGray5)
                    ProgressView()
                }
            }
        }
       .onAppear {
            generateSnapshot()
        }
    }
    
    private func generateSnapshot() {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        options.size = CGSize(width: 400, height: 200)
        options.mapType = .standard
        options.showsBuildings = true
        
        let pinView = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
        let snapshotter = MKMapSnapshotter(options: options)
        
        snapshotter.start { (snapshot, error) in
            if let error = error {
                logger.error("Snapshot generation failed: \(error.localizedDescription, privacy: .public)")
                return
            }
            
            guard let snapshot = snapshot else { return }
            
            UIGraphicsBeginImageContextWithOptions(snapshot.image.size, true, snapshot.image.scale)
            snapshot.image.draw(at: .zero)
            
            let point = snapshot.point(for: coordinate)
            let pinPoint = CGPoint(x: point.x - pinView.bounds.size.width / 2, y: point.y - pinView.bounds.size.height / 2)
            pinView.image?.draw(at: pinPoint)
            
            let finalImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            DispatchQueue.main.async {
                self.snapshotImage = finalImage
            }
        }
    }
}
