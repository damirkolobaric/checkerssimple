import simd

struct Vertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
}

struct Uniforms {
    var modelMatrix: simd_float4x4
    var viewMatrix: simd_float4x4
    var projectionMatrix: simd_float4x4
    var color: SIMD4<Float>
    var lightPosition: SIMD3<Float>
    var cameraPosition: SIMD3<Float>
}

extension simd_float4x4 {
    init(translationX x: Float, y: Float, z: Float) {
        self.init(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(x, y, z, 1)
        )
    }
    
    init(scaleX x: Float, y: Float, z: Float) {
        self.init(
            SIMD4<Float>(x, 0, 0, 0),
            SIMD4<Float>(0, y, 0, 0),
            SIMD4<Float>(0, 0, z, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
    
    init(rotationAngle angle: Float, x: Float, y: Float, z: Float) {
        let c = cos(angle)
        let s = sin(angle)
        
        let column0 = SIMD4<Float>(
            x * x * (1 - c) + c,
            y * x * (1 - c) + z * s,
            z * x * (1 - c) - y * s,
            0
        )
        
        let column1 = SIMD4<Float>(
            x * y * (1 - c) - z * s,
            y * y * (1 - c) + c,
            z * y * (1 - c) + x * s,
            0
        )
        
        let column2 = SIMD4<Float>(
            x * z * (1 - c) + y * s,
            y * z * (1 - c) - x * s,
            z * z * (1 - c) + c,
            0
        )
        
        let column3 = SIMD4<Float>(0, 0, 0, 1)
        
        self.init(column0, column1, column2, column3)
    }
    
    init(perspectiveProjectionFov fov: Float, aspect: Float, near: Float, far: Float) {
        let y = 1 / tan(fov * 0.5)
        let x = y / aspect
        let z = far / (near - far)
        
        self.init(
            SIMD4<Float>(x, 0, 0, 0),
            SIMD4<Float>(0, y, 0, 0),
            SIMD4<Float>(0, 0, z, -1),
            SIMD4<Float>(0, 0, z * near, 0)
        )
    }
    
    init(lookAt eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) {
        let z = normalize(eye - center)
        let x = normalize(cross(up, z))
        let y = cross(z, x)
        
        self.init(
            SIMD4<Float>(x.x, y.x, z.x, 0),
            SIMD4<Float>(x.y, y.y, z.y, 0),
            SIMD4<Float>(x.z, y.z, z.z, 0),
            SIMD4<Float>(-dot(x, eye), -dot(y, eye), -dot(z, eye), 1)
        )
    }
}
