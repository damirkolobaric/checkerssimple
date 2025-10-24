import simd

struct Ray {
    var origin: SIMD3<Float>
    var direction: SIMD3<Float>
}

struct BoundingBox {
    var min: SIMD3<Float>
    var max: SIMD3<Float>
    
    func intersects(ray: Ray) -> Float? {
        let invDir = SIMD3<Float>(1.0 / ray.direction.x, 1.0 / ray.direction.y, 1.0 / ray.direction.z)
        
        let t1 = (min.x - ray.origin.x) * invDir.x
        let t2 = (max.x - ray.origin.x) * invDir.x
        let t3 = (min.y - ray.origin.y) * invDir.y
        let t4 = (max.y - ray.origin.y) * invDir.y
        let t5 = (min.z - ray.origin.z) * invDir.z
        let t6 = (max.z - ray.origin.z) * invDir.z
        
        let tmin = Swift.max(Swift.max(Swift.min(t1, t2), Swift.min(t3, t4)), Swift.min(t5, t6))
        let tmax = Swift.min(Swift.min(Swift.max(t1, t2), Swift.max(t3, t4)), Swift.max(t5, t6))
        
        if tmax < 0 || tmin > tmax {
            return nil
        }
        
        return tmin
    }
    
    func contains(point: SIMD3<Float>) -> Bool {
        return point.x >= min.x && point.x <= max.x &&
               point.y >= min.y && point.y <= max.y &&
               point.z >= min.z && point.z <= max.z
    }
}

struct BoundingSphere {
    var center: SIMD3<Float>
    var radius: Float
    
    func intersects(ray: Ray) -> Float? {
        let oc = ray.origin - center
        let a = dot(ray.direction, ray.direction)
        let b = 2.0 * dot(oc, ray.direction)
        let c = dot(oc, oc) - radius * radius
        let discriminant = b * b - 4 * a * c
        
        if discriminant < 0 {
            return nil
        }
        
        let t = (-b - sqrt(discriminant)) / (2.0 * a)
        return t > 0 ? t : nil
    }
    
    func contains(point: SIMD3<Float>) -> Bool {
        return distance(point, center) <= radius
    }
}

class Picker {
    static func rayFromScreenPoint(_ point: CGPoint,
                                   viewportSize: CGSize,
                                   projectionMatrix: simd_float4x4,
                                   viewMatrix: simd_float4x4) -> Ray {
        // Normalize screen coordinates to NDC (-1 to 1)
        let x = (2.0 * Float(point.x)) / Float(viewportSize.width) - 1.0
        let y = 1.0 - (2.0 * Float(point.y)) / Float(viewportSize.height)
        
        // NDC coordinates
        let rayNDC = SIMD4<Float>(x, y, -1.0, 1.0)
        
        // Clip coordinates
        let rayClip = SIMD4<Float>(rayNDC.x, rayNDC.y, -1.0, 1.0)
        
        // Eye coordinates
        let invProjection = projectionMatrix.inverse
        var rayEye = invProjection * rayClip
        rayEye = SIMD4<Float>(rayEye.x, rayEye.y, -1.0, 0.0)
        
        // World coordinates
        let invView = viewMatrix.inverse
        let rayWorld = invView * rayEye
        
        var direction = SIMD3<Float>(rayWorld.x, rayWorld.y, rayWorld.z)
        direction = normalize(direction)
        
        // Camera position from view matrix
        let origin = SIMD3<Float>(invView.columns.3.x, invView.columns.3.y, invView.columns.3.z)
        
        return Ray(origin: origin, direction: direction)
    }
    
    static func intersectTriangle(ray: Ray, 
                                  v0: SIMD3<Float>, 
                                  v1: SIMD3<Float>, 
                                  v2: SIMD3<Float>) -> Float? {
        let edge1 = v1 - v0
        let edge2 = v2 - v0
        let h = cross(ray.direction, edge2)
        let a = dot(edge1, h)
        
        if abs(a) < 0.00001 {
            return nil
        }
        
        let f = 1.0 / a
        let s = ray.origin - v0
        let u = f * dot(s, h)
        
        if u < 0.0 || u > 1.0 {
            return nil
        }
        
        let q = cross(s, edge1)
        let v = f * dot(ray.direction, q)
        
        if v < 0.0 || u + v > 1.0 {
            return nil
        }
        
        let t = f * dot(edge2, q)
        
        if t > 0.00001 {
            return t
        }
        
        return nil
    }
    
    static func calculateBoundingBox(vertices: [Vertex], transform: simd_float4x4) -> BoundingBox {
        guard !vertices.isEmpty else {
            return BoundingBox(min: SIMD3<Float>(0, 0, 0), max: SIMD3<Float>(0, 0, 0))
        }
        
        var minPoint = SIMD3<Float>(Float.infinity, Float.infinity, Float.infinity)
        var maxPoint = SIMD3<Float>(-Float.infinity, -Float.infinity, -Float.infinity)
        
        for vertex in vertices {
            let transformedPos = transform * SIMD4<Float>(vertex.position.x, vertex.position.y, vertex.position.z, 1.0)
            let pos = SIMD3<Float>(transformedPos.x, transformedPos.y, transformedPos.z)
            
            minPoint.x = min(minPoint.x, pos.x)
            minPoint.y = min(minPoint.y, pos.y)
            minPoint.z = min(minPoint.z, pos.z)
            
            maxPoint.x = max(maxPoint.x, pos.x)
            maxPoint.y = max(maxPoint.y, pos.y)
            maxPoint.z = max(maxPoint.z, pos.z)
        }
        
        return BoundingBox(min: minPoint, max: maxPoint)
    }
    
    static func calculateBoundingSphere(vertices: [Vertex], transform: simd_float4x4) -> BoundingSphere {
        guard !vertices.isEmpty else {
            return BoundingSphere(center: SIMD3<Float>(0, 0, 0), radius: 0)
        }
        
        // Calculate center
        var center = SIMD3<Float>(0, 0, 0)
        for vertex in vertices {
            center += vertex.position
        }
        center /= Float(vertices.count)
        
        // Transform center
        let transformedCenter = transform * SIMD4<Float>(center.x, center.y, center.z, 1.0)
        let finalCenter = SIMD3<Float>(transformedCenter.x, transformedCenter.y, transformedCenter.z)
        
        // Calculate radius
        var radius: Float = 0
        for vertex in vertices {
            let transformedPos = transform * SIMD4<Float>(vertex.position.x, vertex.position.y, vertex.position.z, 1.0)
            let pos = SIMD3<Float>(transformedPos.x, transformedPos.y, transformedPos.z)
            let dist = distance(pos, finalCenter)
            radius = max(radius, dist)
        }
        
        return BoundingSphere(center: finalCenter, radius: radius)
    }
}

extension simd_float4x4 {
    var inverse: simd_float4x4 {
        return simd_inverse(self)
    }
}
