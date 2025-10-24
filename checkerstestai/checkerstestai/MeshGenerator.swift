import Metal

class MeshGenerator {
    static func createBox(width: Float, height: Float, depth: Float) -> (vertices: [Vertex], indices: [UInt16]) {
        let w = width / 2
        let h = height / 2
        let d = depth / 2
        
        let vertices: [Vertex] = [
            // Front face
            Vertex(position: SIMD3<Float>(-w, -h,  d), normal: SIMD3<Float>(0, 0, 1)),
            Vertex(position: SIMD3<Float>( w, -h,  d), normal: SIMD3<Float>(0, 0, 1)),
            Vertex(position: SIMD3<Float>( w,  h,  d), normal: SIMD3<Float>(0, 0, 1)),
            Vertex(position: SIMD3<Float>(-w,  h,  d), normal: SIMD3<Float>(0, 0, 1)),
            
            // Back face
            Vertex(position: SIMD3<Float>(-w, -h, -d), normal: SIMD3<Float>(0, 0, -1)),
            Vertex(position: SIMD3<Float>(-w,  h, -d), normal: SIMD3<Float>(0, 0, -1)),
            Vertex(position: SIMD3<Float>( w,  h, -d), normal: SIMD3<Float>(0, 0, -1)),
            Vertex(position: SIMD3<Float>( w, -h, -d), normal: SIMD3<Float>(0, 0, -1)),
            
            // Top face
            Vertex(position: SIMD3<Float>(-w,  h, -d), normal: SIMD3<Float>(0, 1, 0)),
            Vertex(position: SIMD3<Float>(-w,  h,  d), normal: SIMD3<Float>(0, 1, 0)),
            Vertex(position: SIMD3<Float>( w,  h,  d), normal: SIMD3<Float>(0, 1, 0)),
            Vertex(position: SIMD3<Float>( w,  h, -d), normal: SIMD3<Float>(0, 1, 0)),
            
            // Bottom face
            Vertex(position: SIMD3<Float>(-w, -h, -d), normal: SIMD3<Float>(0, -1, 0)),
            Vertex(position: SIMD3<Float>( w, -h, -d), normal: SIMD3<Float>(0, -1, 0)),
            Vertex(position: SIMD3<Float>( w, -h,  d), normal: SIMD3<Float>(0, -1, 0)),
            Vertex(position: SIMD3<Float>(-w, -h,  d), normal: SIMD3<Float>(0, -1, 0)),
            
            // Right face
            Vertex(position: SIMD3<Float>( w, -h, -d), normal: SIMD3<Float>(1, 0, 0)),
            Vertex(position: SIMD3<Float>( w,  h, -d), normal: SIMD3<Float>(1, 0, 0)),
            Vertex(position: SIMD3<Float>( w,  h,  d), normal: SIMD3<Float>(1, 0, 0)),
            Vertex(position: SIMD3<Float>( w, -h,  d), normal: SIMD3<Float>(1, 0, 0)),
            
            // Left face
            Vertex(position: SIMD3<Float>(-w, -h, -d), normal: SIMD3<Float>(-1, 0, 0)),
            Vertex(position: SIMD3<Float>(-w, -h,  d), normal: SIMD3<Float>(-1, 0, 0)),
            Vertex(position: SIMD3<Float>(-w,  h,  d), normal: SIMD3<Float>(-1, 0, 0)),
            Vertex(position: SIMD3<Float>(-w,  h, -d), normal: SIMD3<Float>(-1, 0, 0))
        ]
        
        let indices: [UInt16] = [
            0, 1, 2, 2, 3, 0,       // Front
            4, 5, 6, 6, 7, 4,       // Back
            8, 9, 10, 10, 11, 8,    // Top
            12, 13, 14, 14, 15, 12, // Bottom
            16, 17, 18, 18, 19, 16, // Right
            20, 21, 22, 22, 23, 20  // Left
        ]
        
        return (vertices, indices)
    }

    static func createPlane(width: Float, height: Float, depth: Float) -> (vertices: [Vertex], indices: [UInt16]) {
        let w = width / 2
        let h = height / 2
        let d = depth / 2
        
        let vertices: [Vertex] = [

            // Top face
            Vertex(position: SIMD3<Float>(-w,  h, -d), normal: SIMD3<Float>(0, 1, 0)),
            Vertex(position: SIMD3<Float>(-w,  h,  d), normal: SIMD3<Float>(0, 1, 0)),
            Vertex(position: SIMD3<Float>( w,  h,  d), normal: SIMD3<Float>(0, 1, 0)),
            Vertex(position: SIMD3<Float>( w,  h, -d), normal: SIMD3<Float>(0, 1, 0))
        ]
        
        let indices: [UInt16] = [
            0, 1, 2, 2, 3, 0
        ]
        
        return (vertices, indices)
    }

    static func createCylinder(radius: Float, height: Float, segments: Int = 32) -> (vertices: [Vertex], indices: [UInt16]) {
        var vertices: [Vertex] = []
        var indices: [UInt16] = []
        
        let halfHeight = height / 2
        
        // Create top and bottom caps
        for i in 0...segments {
            let angle = Float(i) * 2.0 * .pi / Float(segments)
            let x = cos(angle) * radius
            let z = sin(angle) * radius
            
            // Top circle
            vertices.append(Vertex(position: SIMD3<Float>(x, halfHeight, z), 
                                  normal: SIMD3<Float>(0, 1, 0)))
            // Bottom circle
            vertices.append(Vertex(position: SIMD3<Float>(x, -halfHeight, z), 
                                  normal: SIMD3<Float>(0, -1, 0)))
        }
        
        // Create side vertices
        for i in 0...segments {
            let angle = Float(i) * 2.0 * .pi / Float(segments)
            let x = cos(angle) * radius
            let z = sin(angle) * radius
            let normal = normalize(SIMD3<Float>(x, 0, z))
            
            vertices.append(Vertex(position: SIMD3<Float>(x, halfHeight, z), normal: normal))
            vertices.append(Vertex(position: SIMD3<Float>(x, -halfHeight, z), normal: normal))
        }
        
        // Center vertices for caps
        let topCenterIndex = UInt16(vertices.count)
        vertices.append(Vertex(position: SIMD3<Float>(0, halfHeight, 0), 
                              normal: SIMD3<Float>(0, 1, 0)))
        let bottomCenterIndex = UInt16(vertices.count)
        vertices.append(Vertex(position: SIMD3<Float>(0, -halfHeight, 0), 
                              normal: SIMD3<Float>(0, -1, 0)))
        
        // Top cap indices
        for i in 0..<segments {
            indices.append(contentsOf: [topCenterIndex, UInt16(i * 2), UInt16((i + 1) * 2)])
        }
        
        // Bottom cap indices
        for i in 0..<segments {
            indices.append(contentsOf: [bottomCenterIndex, UInt16((i + 1) * 2 + 1), UInt16(i * 2 + 1)])
        }
        
        // Side indices
        let sideStartIndex = UInt16((segments + 1) * 2)
        for i in 0..<segments {
            let base = sideStartIndex + UInt16(i * 2)
            indices.append(contentsOf: [base, base + 2, base + 1])
            indices.append(contentsOf: [base + 1, base + 2, base + 3])
        }
        
        return (vertices, indices)
    }
    
    static func createCone(radius: Float, height: Float, segments: Int = 32) -> (vertices: [Vertex], indices: [UInt16]) {
        var vertices: [Vertex] = []
        var indices: [UInt16] = []
        
        // Apex
        let apexIndex = UInt16(vertices.count)
        vertices.append(Vertex(position: SIMD3<Float>(0, height, 0), 
                              normal: SIMD3<Float>(0, 1, 0)))
        
        // Base circle
        for i in 0...segments {
            let angle = Float(i) * 2.0 * .pi / Float(segments)
            let x = cos(angle) * radius
            let z = sin(angle) * radius
            
            let sideNormal = normalize(SIMD3<Float>(x, height / radius, z))
            vertices.append(Vertex(position: SIMD3<Float>(x, 0, z), normal: sideNormal))
        }
        
        // Base center
        let baseCenterIndex = UInt16(vertices.count)
        vertices.append(Vertex(position: SIMD3<Float>(0, 0, 0), 
                              normal: SIMD3<Float>(0, -1, 0)))
        
        // Base vertices for bottom face
        for i in 0...segments {
            let angle = Float(i) * 2.0 * .pi / Float(segments)
            let x = cos(angle) * radius
            let z = sin(angle) * radius
            vertices.append(Vertex(position: SIMD3<Float>(x, 0, z), 
                                  normal: SIMD3<Float>(0, -1, 0)))
        }
        
        // Side faces
        for i in 0..<segments {
            indices.append(contentsOf: [apexIndex, UInt16(i + 2), UInt16(i + 1)])
        }
        
        // Bottom face
        let bottomStartIndex = baseCenterIndex + 1
        for i in 0..<segments {
            indices.append(contentsOf: [baseCenterIndex, bottomStartIndex + UInt16(i), bottomStartIndex + UInt16(i + 1)])
        }
        
        return (vertices, indices)
    }
}
