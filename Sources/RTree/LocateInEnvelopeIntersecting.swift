//
//  LocateInEnvelopeIntersecting.swift
//  RTree
//
//  Created by Markus Kieselmann on 25.09.20.
//

import Foundation

public struct LocateInEnvelopeIntersecting<T>
where
    T: SpatialObject
{
    var nodes: [RTreeNode<T>]
    let envelope: BoundingRectangle<T.Point>

    init(nodes: [RTreeNode<T>], envelope: BoundingRectangle<T.Point>) {
        self.nodes = nodes
        self.envelope = envelope

    }

    init(root: DirectoryNodeData<T>, envelope: BoundingRectangle<T.Point>) {
        let currentNodes: [RTreeNode<T>]
        if envelope.intersects(root.boundingBox!) {
            currentNodes = root.children!
        } else {
            currentNodes = []
        }

       self = LocateInEnvelopeIntersecting(nodes: currentNodes, envelope: envelope)
    }
}

extension LocateInEnvelopeIntersecting {

    public mutating func next() -> T? {
        while let current = self.nodes.popLast() {
            switch current {
            case .directoryNode(var data):
                guard shouldUnpackParent(data) else { continue }
                if data.children == nil {
                    try! data.load()
                }
                nodes.append(contentsOf: data.children!)
            case .leaf(let t):
                if shouldUnpackLeaf(t) {
                    return t
                }
            }
        }
        return nil
    }
}

extension LocateInEnvelopeIntersecting {

    fileprivate func shouldUnpackParent(_ parent: DirectoryNodeData<T>) -> Bool {
        envelope.intersects(parent.boundingBox!)
    }

    fileprivate func shouldUnpackLeaf(_ leaf: T) -> Bool {
        leaf.minimumBoundingRectangle().intersects(envelope)
    }
}
