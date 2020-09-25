import XCTest
@testable import RTree

struct Point2D: PointN {
    typealias Scalar = Double
    
    var x: Scalar
    var y: Scalar
    
    init(x: Scalar, y: Scalar) {
        self.x = x
        self.y = y
        
    }
    
    func dimensions() -> Int {
        2
        
    }
    
    static func from(value: Double) -> Self {
        Point2D(x: value, y: value)
        
    }
    
    subscript(index: Int) -> Scalar {
        get {
            if index == 0 {
                return self.x
                
            } else {
                return self.y
                
            }
            
        }
        set(newValue) {
            if index == 0 {
                self.x = newValue
                
            } else {
                self.y = newValue
                
            }
             
        }
        
    }
    
}

extension Point2D: Equatable {
    static func == (lhs: Point2D, rhs: Point2D) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y
        
    }
    
}

struct Element: SpatialObject {
    typealias Point = Point2D
        
    let point: Point
    let hello = "world"
    
    func minimumBoundingRectangle() -> BoundingRectangle<Point2D> {
        BoundingRectangle(lower: self.point, upper: self.point)
        
    }
    
    func distanceSquared(point: Point2D) -> Double {
        pow(point.x - self.point.x, 2) + pow(point.y - self.point.y, 2)
        
    }
    
}

extension Element: Equatable {
    static func == (lhs: Element, rhs: Element) -> Bool {
        lhs.point == rhs.point && lhs.hello == rhs.hello
        
    }
    
}

struct Rectangle: SpatialObject {
    typealias Point = Point2D

    private let boundingRectangle: BoundingRectangle<Point>

    init(lower: Point, upper: Point) {
        self.boundingRectangle = BoundingRectangle(lower: lower, upper: upper)
    }

    var lower: Point { boundingRectangle.lower }
    var upper: Point { boundingRectangle.upper }

    func minimumBoundingRectangle() -> BoundingRectangle<Point2D> {
        boundingRectangle
    }

    func distanceSquared(point: Point2D) -> Double {
        boundingRectangle.distanceSquared(point: point)
    }
}

extension Rectangle: Equatable {}

@available(OSX 10.12, *)
final class RTreeTests: XCTestCase {
    func testInit() throws {
        var path = FileManager.default.temporaryDirectory
        path.appendPathComponent("testRTreeInit.db")
        
        let tree = try RTree<Element>(path: path)
        
        XCTAssertEqual(tree.size, 0)
        
        try? FileManager.default.removeItem(at: path)
        
    }
    
    func testInsert() throws {
        var path = FileManager.default.temporaryDirectory
        path.appendPathComponent("testRTreeInsert.db")
        
        var tree = try RTree<Element>(path: path)
        
        try tree.insert(Element(point: Point2D(x: 0, y: 0)))
        try tree.insert(Element(point: Point2D(x: 1, y: 1)))
        
        try? FileManager.default.removeItem(at: path)
        
    }
    
    func testLotsOfInserts() throws {
        var path = FileManager.default.temporaryDirectory
        path.appendPathComponent("testRTreeLotsOfInserts.db")
        
        var tree = try RTree<Element>(path: path)
        
        for i in 0..<200 {
            try tree.insert(Element(point: Point2D(x: Double(i), y: Double(i))))
            
        }
        
        try? FileManager.default.removeItem(at: path)
        
    }
    
    func testNearestNeighbor() throws {
        var path = FileManager.default.temporaryDirectory
        path.appendPathComponent("testRTreeNearestNeighbor.db")
        
        var tree = try RTree<Element>(path: path)
        let zerozero = Element(point: Point2D(x: 0, y: 0))
        let oneone = Element(point: Point2D(x: 1, y: 1))
        let threethree = Element(point: Point2D(x: 3, y: 3))
        
        try tree.insert(oneone)
        try tree.insert(threethree)
        
        XCTAssertEqual(try tree.nearestNeighbor(zerozero.point)!, oneone)
        
        try? FileManager.default.removeItem(at: path)
        
    }

    func testLocateInEnvelopeIntersecting() throws {
        var path = FileManager.default.temporaryDirectory
        path.appendPathComponent("testRTreeLocateInEnvelopeIntersecting.db")

        var tree = try RTree<Rectangle>(path: path)

        let leftPiece = Rectangle(lower: Point2D(x: 0.0, y: 0.0), upper: Point2D(x: 0.4, y: 1.0))
        let rightPiece = Rectangle(lower: Point2D(x: 0.6, y: 0.0), upper: Point2D(x: 1.0, y: 1.0))
        let middlePiece = Rectangle(lower: Point2D(x: 0.25, y: 0.0), upper: Point2D(x: 0.75, y: 1.0))

        try tree.insert(leftPiece)
        try tree.insert(rightPiece)
        try tree.insert(middlePiece)

        let elementsIntersectingLeftPiece = try tree.locateInEnvelopeIntersecting(leftPiece.minimumBoundingRectangle())
        //The left piece should not intersect the right piece!
        XCTAssertEqual(elementsIntersectingLeftPiece.count, 2)

        let elementsIntersectingMiddle = try tree.locateInEnvelopeIntersecting(middlePiece.minimumBoundingRectangle())
        // Only the middle piece intersects all pieces within the tree
        XCTAssertEqual(elementsIntersectingMiddle.count, 3)

        let largePiece = BoundingRectangle(lower: Point2D(x: -100, y: -100), upper: Point2D(x: 100, y: 100))
        let elementsIntersectingLargePiece = try tree.locateInEnvelopeIntersecting(largePiece)
        // Any element that is fully contained should also be returned
        XCTAssertEqual(elementsIntersectingLargePiece.count, 3)

        try? FileManager.default.removeItem(at: path)
    }
    
}
