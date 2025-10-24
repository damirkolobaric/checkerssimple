import UIKit
import MetalKit
import simd

// MARK: - Advanced 3D Object Picking Examples

/*
 This file demonstrates various techniques for detecting clicks on 3D objects in Metal:
 
 1. Raycasting with Bounding Volumes (Fast)
 2. Raycasting with Triangle Intersection (Accurate)
 3. Color-based Picking (GPU-based)
 4. Depth Buffer Reading (Precise)
*/

// MARK: - Example 1: Simple Raycasting with Bounding Sphere

class Example1_SimplePicking {
    func detectClick(screenPoint: CGPoint, 
                    viewportSize: CGSize,
                    objects: [(position: SIMD3<Float>, radius: Float)],
                    projectionMatrix: simd_float4x4,
                    viewMatrix: simd_float4x4) -> Int? {
        
        // Create ray from screen point
        let ray = Picker.rayFromScreenPoint(screenPoint,
                                           viewportSize: viewportSize,
                                           projectionMatrix: projectionMatrix,
                                           viewMatrix: viewMatrix)
        
        var closestIndex: Int?
        var closestDistance: Float = Float.infinity
        
        // Test each object
        for (index, object) in objects.enumerated() {
            let sphere = BoundingSphere(center: object.position, radius: object.radius)
            
            if let distance = sphere.intersects(ray: ray) {
                if distance < closestDistance {
                    closestDistance = distance
                    closestIndex = index
                }
            }
        }
        
        return closestIndex
    }
}

// MARK: - Example 2: Raycasting with Triangle Intersection

class Example2_TrianglePicking {
    struct MeshObject {
        var vertices: [Vertex]
        var indices: [UInt16]
        var transform: simd_float4x4
    }
    
    func detectClick(screenPoint: CGPoint,
                    viewportSize: CGSize,
                    objects: [MeshObject],
                    projectionMatrix: simd_float4x4,
                    viewMatrix: simd_float4x4) -> Int? {
        
        let ray = Picker.rayFromScreenPoint(screenPoint,
                                           viewportSize: viewportSize,
                                           projectionMatrix: projectionMatrix,
                                           viewMatrix: viewMatrix)
        
        var closestIndex: Int?
        var closestDistance: Float = Float.infinity
        
        for (objectIndex, object) in objects.enumerated() {
            // First check bounding box for quick rejection
            let bounds = Picker.calculateBoundingBox(vertices: object.vertices, 
                                                     transform: object.transform)
            
            guard bounds.intersects(ray: ray) != nil else {
                continue
            }
            
            // Check actual triangles
            for i in stride(from: 0, to: object.indices.count, by: 3) {
                let i0 = Int(object.indices[i])
                let i1 = Int(object.indices[i + 1])
                let i2 = Int(object.indices[i + 2])
                
                // Transform vertices to world space
                let v0World = object.transform * SIMD4<Float>(object.vertices[i0].position, 1.0)
                let v1World = object.transform * SIMD4<Float>(object.vertices[i1].position, 1.0)
                let v2World = object.transform * SIMD4<Float>(object.vertices[i2].position, 1.0)
                
                let v0 = SIMD3<Float>(v0World.x, v0World.y, v0World.z)
                let v1 = SIMD3<Float>(v1World.x, v1World.y, v1World.z)
                let v2 = SIMD3<Float>(v2World.x, v2World.y, v2World.z)
                
                if let distance = Picker.intersectTriangle(ray: ray, v0: v0, v1: v1, v2: v2) {
                    if distance < closestDistance {
                        closestDistance = distance
                        closestIndex = objectIndex
                    }
                }
            }
        }
        
        return closestIndex
    }
}

// MARK: - Example 3: Multi-Object Picking with Highlighting

class Example3_PickingWithHighlight {
    var selectedObjectIndex: Int?
    var hoveredObjectIndex: Int?
    
    func handleTap(_ point: CGPoint,
                   viewportSize: CGSize,
                   objects: [(position: SIMD3<Float>, radius: Float, name: String)],
                   projectionMatrix: simd_float4x4,
                   viewMatrix: simd_float4x4) {
        
        let ray = Picker.rayFromScreenPoint(point,
                                           viewportSize: viewportSize,
                                           projectionMatrix: projectionMatrix,
                                           viewMatrix: viewMatrix)
        
        var closestIndex: Int?
        var closestDistance: Float = Float.infinity
        
        for (index, object) in objects.enumerated() {
            let sphere = BoundingSphere(center: object.position, radius: object.radius)
            
            if let distance = sphere.intersects(ray: ray) {
                if distance < closestDistance {
                    closestDistance = distance
                    closestIndex = index
                }
            }
        }
        
        if let index = closestIndex {
            selectedObjectIndex = index
            print("Selected object: \(objects[index].name)")
        } else {
            selectedObjectIndex = nil
            print("Deselected")
        }
    }
    
    func handleHover(_ point: CGPoint,
                    viewportSize: CGSize,
                    objects: [(position: SIMD3<Float>, radius: Float)],
                    projectionMatrix: simd_float4x4,
                    viewMatrix: simd_float4x4) {
        
        let ray = Picker.rayFromScreenPoint(point,
                                           viewportSize: viewportSize,
                                           projectionMatrix: projectionMatrix,
                                           viewMatrix: viewMatrix)
        
        var closestIndex: Int?
        var closestDistance: Float = Float.infinity
        
        for (index, object) in objects.enumerated() {
            let sphere = BoundingSphere(center: object.position, radius: object.radius)
            
            if let distance = sphere.intersects(ray: ray) {
                if distance < closestDistance {
                    closestDistance = distance
                    closestIndex = index
                }
            }
        }
        
        hoveredObjectIndex = closestIndex
    }
}

// MARK: - Example 4: Picking with Bounding Box

class Example4_BoundingBoxPicking {
    struct BoxObject {
        var center: SIMD3<Float>
        var size: SIMD3<Float>
        var rotation: simd_float4x4
    }
    
    func detectClick(screenPoint: CGPoint,
                    viewportSize: CGSize,
                    objects: [BoxObject],
                    projectionMatrix: simd_float4x4,
                    viewMatrix: simd_float4x4) -> Int? {
        
        let ray = Picker.rayFromScreenPoint(screenPoint,
                                           viewportSize: viewportSize,
                                           projectionMatrix: projectionMatrix,
                                           viewMatrix: viewMatrix)
        
        var closestIndex: Int?
        var closestDistance: Float = Float.infinity
        
        for (index, object) in objects.enumerated() {
            let halfSize = object.size / 2
            let bounds = BoundingBox(min: object.center - halfSize,
                                    max: object.center + halfSize)
            
            if let distance = bounds.intersects(ray: ray) {
                if distance < closestDistance {
                    closestDistance = distance
                    closestIndex = index
                }
            }
        }
        
        return closestIndex
    }
}

// MARK: - Example 5: Getting Click Position in 3D Space

class Example5_WorldSpacePosition {
    func getClickPositionInWorld(screenPoint: CGPoint,
                                viewportSize: CGSize,
                                projectionMatrix: simd_float4x4,
                                viewMatrix: simd_float4x4,
                                planeY: Float = 0.0) -> SIMD3<Float>? {
        
        let ray = Picker.rayFromScreenPoint(screenPoint,
                                           viewportSize: viewportSize,
                                           projectionMatrix: projectionMatrix,
                                           viewMatrix: viewMatrix)
        
        // Intersect with horizontal plane at Y = planeY
        // Plane equation: Y = planeY
        // Ray equation: P = origin + t * direction
        
        if abs(ray.direction.y) < 0.001 {
            return nil // Ray is parallel to plane
        }
        
        let t = (planeY - ray.origin.y) / ray.direction.y
        
        if t < 0 {
            return nil // Intersection is behind camera
        }
        
        let hitPoint = ray.origin + t * ray.direction
        return hitPoint
    }
}

// MARK: - Example 6: Drag and Drop 3D Objects

class Example6_DragAndDrop {
    var draggedObjectIndex: Int?
    var dragOffset: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    
    func startDrag(screenPoint: CGPoint,
                  viewportSize: CGSize,
                  objects: inout [(position: SIMD3<Float>, radius: Float)],
                  projectionMatrix: simd_float4x4,
                  viewMatrix: simd_float4x4) {
        
        let ray = Picker.rayFromScreenPoint(screenPoint,
                                           viewportSize: viewportSize,
                                           projectionMatrix: projectionMatrix,
                                           viewMatrix: viewMatrix)
        
        for (index, object) in objects.enumerated() {
            let sphere = BoundingSphere(center: object.position, radius: object.radius)
            
            if sphere.intersects(ray: ray) != nil {
                draggedObjectIndex = index
                
                // Calculate offset from click point to object center
                if let worldPos = Example5_WorldSpacePosition().getClickPositionInWorld(
                    screenPoint: screenPoint,
                    viewportSize: viewportSize,
                    projectionMatrix: projectionMatrix,
                    viewMatrix: viewMatrix,
                    planeY: object.position.y) {
                    
                    dragOffset = object.position - worldPos
                }
                break
            }
        }
    }
    
    func updateDrag(screenPoint: CGPoint,
                   viewportSize: CGSize,
                   objects: inout [(position: SIMD3<Float>, radius: Float)],
                   projectionMatrix: simd_float4x4,
                   viewMatrix: simd_float4x4) {
        
        guard let index = draggedObjectIndex else { return }
        
        if let worldPos = Example5_WorldSpacePosition().getClickPositionInWorld(
            screenPoint: screenPoint,
            viewportSize: viewportSize,
            projectionMatrix: projectionMatrix,
            viewMatrix: viewMatrix,
            planeY: objects[index].position.y) {
            
            objects[index].position = worldPos + dragOffset
        }
    }
    
    func endDrag() {
        draggedObjectIndex = nil
    }
}

// MARK: - Usage Example in View Controller

/*
class MyGameViewController: UIViewController {
    var metalView: MTKView!
    var renderer: Renderer!
    let picker = Example1_SimplePicking()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGestures()
    }
    
    func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        metalView.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: metalView)
        
        // Prepare object data
        var objects: [(position: SIMD3<Float>, radius: Float)] = []
        for piece in renderer.pieces {
            let pos = SIMD3<Float>(piece.transform.columns.3.x,
                                  piece.transform.columns.3.y,
                                  piece.transform.columns.3.z)
            objects.append((position: pos, radius: 0.5))
        }
        
        // Detect which object was clicked
        if let clickedIndex = picker.detectClick(
            screenPoint: location,
            viewportSize: metalView.bounds.size,
            objects: objects,
            projectionMatrix: renderer.getProjectionMatrix(aspectRatio: Float(metalView.bounds.width / metalView.bounds.height)),
            viewMatrix: renderer.getViewMatrix()) {
            
            print("Clicked on object at index: \(clickedIndex)")
            // Handle the click...
        }
    }
}
*/
