import Metal
import MetalKit

class Renderer: NSObject {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState!
    var depthStencilState: MTLDepthStencilState!
    
    var boardSquares: [(vertexBuffer: MTLBuffer, indexBuffer: MTLBuffer, indexCount: Int)] = []
    var pieces: [(vertexBuffer: MTLBuffer, indexBuffer: MTLBuffer, indexCount: Int, transform: simd_float4x4, color: SIMD4<Float>, isKing: Bool)] = []
    
    var selectedPieceIndex: Int?
    var lastPlayedPieceIndex: Int?
    var animationTime: Float = 0
    
    // Move animation
    var animatingPieceIndex: Int?
    var animationStartPosition: SIMD3<Float>?
    var animationEndPosition: SIMD3<Float>?
    var animationProgress: Float = 0
    var animationDuration: Float = 0.3 // seconds
    
    // Capture animation
    var capturingPieceIndices: [Int] = []
    var captureAnimationProgress: [Int: Float] = [:]
    var captureAnimationDuration: Float = 0.4 // seconds
    
    var cameraPosition = SIMD3<Float>(4, 8, 10)
    var cameraRotation: Float = 0
    var cameraPitch: Float = Float.pi / 6
    
    // Camera animation
    var cameraAnimating = false
    var cameraAnimationProgress: Float = 0
    var cameraStartPosition: SIMD3<Float>?
    var cameraStartRotation: Float = 0
    var cameraTargetPosition: SIMD3<Float>?
    var cameraTargetRotation: Float = 0
    var cameraAnimationDuration: Float = 2.0
    
    // Victory/Defeat effects
    var victoryEffectActive = false
    var defeatEffectActive = false
    var victoryEffectTime: Float = 0
    
    init(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        super.init()
        
        buildPipeline()
        buildDepthStencilState()
        createBoard()
        createPieces()
        
        // Start camera animation
        startCameraIntro()
    }
    
    func startCameraIntro() {
        // Start from high and far position
        cameraStartPosition = SIMD3<Float>(8, 15, 15)
        cameraStartRotation = Float.pi * 0.25
        cameraTargetPosition = SIMD3<Float>(4, 8, 10)
        cameraTargetRotation = 0
        
        cameraPosition = cameraStartPosition!
        cameraRotation = cameraStartRotation
        cameraAnimating = true
        cameraAnimationProgress = 0
    }
    
    func startVictoryEffect() {
        victoryEffectActive = true
        defeatEffectActive = false
        victoryEffectTime = 0
        
        // Zoom and rotate around winning pieces
        cameraStartPosition = cameraPosition
        cameraStartRotation = cameraRotation
        cameraTargetPosition = SIMD3<Float>(3.5, 6, 8)
        cameraTargetRotation = cameraRotation + Float.pi * 2
        cameraAnimating = true
        cameraAnimationProgress = 0
        cameraAnimationDuration = 3.0
    }
    
    func startDefeatEffect() {
        victoryEffectActive = false
        defeatEffectActive = true
        victoryEffectTime = 0
        
        // Pull back and show full board
        cameraStartPosition = cameraPosition
        cameraStartRotation = cameraRotation
        cameraTargetPosition = SIMD3<Float>(4, 12, 12)
        cameraTargetRotation = cameraRotation
        cameraAnimating = true
        cameraAnimationProgress = 0
        cameraAnimationDuration = 2.0
    }
    
    func buildPipeline() {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not load Metal library")
        }
        
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Could not create pipeline state: \(error)")
        }
    }
    
    func buildDepthStencilState() {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
    
    func createBoard() {
        for row in 0..<8 {
            for col in 0..<8 {
                let (vertices, indices) = MeshGenerator.createBox(width: 1.0, height: 0.2, depth: 1.0)
                
                guard let vertexBuffer = device.makeBuffer(bytes: vertices,
                                                          length: MemoryLayout<Vertex>.stride * vertices.count,
                                                          options: []),
                      let indexBuffer = device.makeBuffer(bytes: indices,
                                                         length: MemoryLayout<UInt16>.stride * indices.count,
                                                         options: []) else {
                    fatalError("Could not create buffers")
                }
                
                boardSquares.append((vertexBuffer, indexBuffer, indices.count))
            }
        }
    }
    
    func createPieces() {
        // Red pieces
        for row in 0..<3 {
            for col in 0..<8 {
                if (row + col) % 2 == 1 {
                    createPiece(at: (row, col), color: SIMD4<Float>(0.8, 0.1, 0.1, 1.0))
                }
            }
        }
        
        // Black pieces
        for row in 5..<8 {
            for col in 0..<8 {
                if (row + col) % 2 == 1 {
                    createPiece(at: (row, col), color: SIMD4<Float>(0.1, 0.1, 0.1, 1.0))
                }
            }
        }
    }
    
    func createPiece(at position: (Int, Int), color: SIMD4<Float>) {
        let (vertices, indices) = MeshGenerator.createCylinder(radius: 0.4, height: 0.3)
        
        guard let vertexBuffer = device.makeBuffer(bytes: vertices,
                                                  length: MemoryLayout<Vertex>.stride * vertices.count,
                                                  options: []),
              let indexBuffer = device.makeBuffer(bytes: indices,
                                                 length: MemoryLayout<UInt16>.stride * indices.count,
                                                 options: []) else {
            fatalError("Could not create buffers")
        }
        
        let transform = simd_float4x4(translationX: Float(position.1), 
                                      y: 0.25, 
                                      z: Float(position.0))
        
        pieces.append((vertexBuffer, indexBuffer, indices.count, transform, color, false))
    }
    
    func movePiece(at index: Int, to position: (Int, Int)) {
        guard index < pieces.count else { return }
        
        // Store start position for animation
        let currentTransform = pieces[index].transform
        animationStartPosition = SIMD3<Float>(
            currentTransform.columns.3.x,
            currentTransform.columns.3.y,
            currentTransform.columns.3.z
        )
        
        // Store end position for animation
        animationEndPosition = SIMD3<Float>(
            Float(position.1),
            0.25,
            Float(position.0)
        )
        
        // Start animation
        animatingPieceIndex = index
        animationProgress = 0
        
        // Promote to king if reached opposite end
        let isRed = pieces[index].color.x > 0.5
        if (isRed && position.0 == 7) || (!isRed && position.0 == 0) {
            pieces[index].isKing = true
        }
    }
    
    func removePiece(at index: Int) {
        guard index < pieces.count else { return }
        pieces.remove(at: index)
    }
    
    func capturePiece(at index: Int) {
        guard index < pieces.count else { return }
        // Start capture animation
        if !capturingPieceIndices.contains(index) {
            capturingPieceIndices.append(index)
            captureAnimationProgress[index] = 0
        }
    }
    
    func isAnimating() -> Bool {
        return animatingPieceIndex != nil
    }
    
    func getProjectionMatrix(aspectRatio: Float) -> simd_float4x4 {
        return simd_float4x4(perspectiveProjectionFov: Float.pi / 3,
                            aspect: aspectRatio,
                            near: 0.1,
                            far: 100)
    }
    
    func getViewMatrix() -> simd_float4x4 {
        let eye = SIMD3<Float>(
            cameraPosition.x * cos(cameraRotation),
            cameraPosition.y,
            cameraPosition.z * sin(cameraRotation)
        )
        return simd_float4x4(lookAt: eye,
                            center: SIMD3<Float>(3.5, 0, 3.5),
                            up: SIMD3<Float>(0, 1, 0))
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setDepthStencilState(depthStencilState)
        
        let aspect = Float(view.bounds.width / view.bounds.height)
        let projectionMatrix = simd_float4x4(perspectiveProjectionFov: Float.pi / 3,
                                            aspect: aspect,
                                            near: 0.1,
                                            far: 100)
        
        let eye = SIMD3<Float>(
            cameraPosition.x * cos(cameraRotation),
            cameraPosition.y,
            cameraPosition.z * sin(cameraRotation)
        )
        let viewMatrix = simd_float4x4(lookAt: eye,
                                       center: SIMD3<Float>(3.5, 0, 3.5),
                                       up: SIMD3<Float>(0, 1, 0))
        
        // Draw board squares
        for (index, square) in boardSquares.enumerated() {
            let row = index / 8
            let col = index % 8
            
            let modelMatrix = simd_float4x4(translationX: Float(col), y: -0.1, z: Float(row))
            let color = (row + col) % 2 == 0 ? 
                SIMD4<Float>(0.9, 0.9, 0.9, 1.0) : 
                SIMD4<Float>(0.4, 0.2, 0.1, 1.0)
            
            var uniforms = Uniforms(
                modelMatrix: modelMatrix,
                viewMatrix: viewMatrix,
                projectionMatrix: projectionMatrix,
                color: color,
                lightPosition: SIMD3<Float>(5, 10, 5),
                cameraPosition: eye
            )
            
            renderEncoder.setVertexBuffer(square.vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
            renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
            renderEncoder.drawIndexedPrimitives(type: .triangle,
                                               indexCount: square.indexCount,
                                               indexType: .uint16,
                                               indexBuffer: square.indexBuffer,
                                               indexBufferOffset: 0)
        }
        
        // Update animation time
        animationTime += 0.016 // Approximately 60 FPS
        
        // Update camera animation
        if cameraAnimating {
            cameraAnimationProgress += 0.016 / cameraAnimationDuration
            if cameraAnimationProgress >= 1.0 {
                cameraAnimating = false
                cameraPosition = cameraTargetPosition ?? cameraPosition
                cameraRotation = cameraTargetRotation
                cameraAnimationProgress = 0
            } else {
                // Ease-in-out interpolation
                let t = cameraAnimationProgress
                let easedT = t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
                
                if let startPos = cameraStartPosition, let targetPos = cameraTargetPosition {
                    cameraPosition = SIMD3<Float>(
                        startPos.x + (targetPos.x - startPos.x) * easedT,
                        startPos.y + (targetPos.y - startPos.y) * easedT,
                        startPos.z + (targetPos.z - startPos.z) * easedT
                    )
                }
                
                cameraRotation = cameraStartRotation + (cameraTargetRotation - cameraStartRotation) * easedT
            }
        }
        
        // Update victory/defeat effect time
        if victoryEffectActive || defeatEffectActive {
            victoryEffectTime += 0.016
        }
        
        // Update move animation
        if animatingPieceIndex != nil {
            animationProgress += 0.016 / animationDuration
            if animationProgress >= 1.0 {
                // Animation complete - set final position
                if let pieceIndex = animatingPieceIndex,
                   let endPos = animationEndPosition {
                    let finalTransform = simd_float4x4(translationX: endPos.x,
                                                       y: endPos.y,
                                                       z: endPos.z)
                    pieces[pieceIndex].transform = finalTransform
                }
                animatingPieceIndex = nil
                animationStartPosition = nil
                animationEndPosition = nil
                animationProgress = 0
            }
        }
        
        // Update capture animations
        var completedCaptures: [Int] = []
        for index in capturingPieceIndices {
            if let progress = captureAnimationProgress[index] {
                let newProgress = progress + 0.016 / captureAnimationDuration
                captureAnimationProgress[index] = newProgress
                
                if newProgress >= 1.0 {
                    completedCaptures.append(index)
                }
            }
        }
        
        // Remove completed captured pieces (in reverse order to maintain indices)
        for index in completedCaptures.sorted(by: >) {
            if let arrayIndex = capturingPieceIndices.firstIndex(of: index) {
                capturingPieceIndices.remove(at: arrayIndex)
                captureAnimationProgress.removeValue(forKey: index)
                
                // Find and remove the piece
                if index < pieces.count {
                    pieces.remove(at: index)
                }
            }
        }
        
        // Draw pieces
        for (index, piece) in pieces.enumerated() {
            // Calculate transform with animation
            var pieceTransform = piece.transform
            var alpha: Float = 1.0
            
            // Apply movement animation if this piece is animating
            if let animatingIndex = animatingPieceIndex,
               animatingIndex == index,
               let startPos = animationStartPosition,
               let endPos = animationEndPosition {
                
                // Ease-in-out interpolation for smooth animation
                let t = animationProgress
                let easedT = t < 0.5 
                    ? 2 * t * t 
                    : 1 - pow(-2 * t + 2, 2) / 2
                
                // Interpolate position
                let currentPos = SIMD3<Float>(
                    startPos.x + (endPos.x - startPos.x) * easedT,
                    startPos.y + (endPos.y - startPos.y) * easedT + sin(easedT * Float.pi) * 0.5, // Arc motion
                    startPos.z + (endPos.z - startPos.z) * easedT
                )
                
                pieceTransform = simd_float4x4(translationX: currentPos.x,
                                               y: currentPos.y,
                                               z: currentPos.z)
            }
            
            // Apply capture animation if this piece is being captured
            if let captureProgress = captureAnimationProgress[index] {
                let currentTransform = pieceTransform
                let basePos = SIMD3<Float>(
                    currentTransform.columns.3.x,
                    currentTransform.columns.3.y,
                    currentTransform.columns.3.z
                )
                
                // Fall down while fading
                let fallDistance: Float = 2.0
                let newY = basePos.y - (fallDistance * captureProgress)
                
                // Fade out
                alpha = 1.0 - captureProgress
                
                // Apply rotation for dramatic effect
                let rotationAngle = captureProgress * Float.pi * 2
                let rotationMatrix = simd_float4x4(rotationY: rotationAngle)
                let translationMatrix = simd_float4x4(translationX: basePos.x,
                                                      y: newY,
                                                      z: basePos.z)
                
                pieceTransform = translationMatrix * rotationMatrix
            }
            
            // Apply highlight effect
            var pieceColor = SIMD4<Float>(piece.color.x, piece.color.y, piece.color.z, alpha)
            let isSelected = selectedPieceIndex == index
            let isLastPlayed = lastPlayedPieceIndex == index
            let isRedPiece = piece.color.x > 0.5 // Red pieces have high red component
            
            // Victory effect - make winning pieces glow and pulse
            if victoryEffectActive {
                let pulse = (sin(victoryEffectTime * 5) + 1.0) * 0.5
                if isRedPiece {
                    // Red pieces glow bright gold/white
                    pieceColor = SIMD4<Float>(
                        min(1.0, piece.color.x + 0.5 * pulse),
                        min(1.0, piece.color.y + 0.8 * pulse),
                        min(1.0, piece.color.z + 0.3 * pulse),
                        alpha
                    )
                }
            }
            
            // Defeat effect - make losing pieces dim and desaturate
            if defeatEffectActive {
                let dimFactor: Float = 0.5 - (sin(victoryEffectTime * 3) + 1.0) * 0.1
                if !isRedPiece {
                    // Black pieces glow bright cyan
                    pieceColor = SIMD4<Float>(
                        min(1.0, piece.color.x + 0.6 * (1.0 - dimFactor)),
                        min(1.0, piece.color.y + 0.8 * (1.0 - dimFactor)),
                        min(1.0, piece.color.z + 1.0 * (1.0 - dimFactor)),
                        alpha
                    )
                } else {
                    // Red pieces become dimmer
                    pieceColor = SIMD4<Float>(
                        piece.color.x * dimFactor,
                        piece.color.y * dimFactor,
                        piece.color.z * dimFactor,
                        alpha
                    )
                }
            }
            
            if isSelected {
                // Different highlight colors for red vs black pieces
                let pulse = (sin(animationTime * 3) + 1.0) * 0.25 + 0.5 // Range 0.5 to 1.0
                
                if isRedPiece {
                    // Red piece selected: Bright orange/yellow glow
                    pieceColor = SIMD4<Float>(
                        min(0.9 + 0.1 * pulse, 1.0),  // Very bright red
                        min(0.5 * pulse, 0.7),         // Medium-high green (orange tint)
                        0.1,                           // Low blue
                        alpha
                    )
                } else {
                    // Black piece selected: Cyan/blue glow
                    pieceColor = SIMD4<Float>(
                        min(0.2 + 0.3 * pulse, 0.6),  // Some red for lighter appearance
                        min(0.5 + 0.3 * pulse, 0.9),  // High green (cyan tint)
                        min(0.7 + 0.3 * pulse, 1.0),  // Very high blue
                        alpha
                    )
                }
            } else if isLastPlayed {
                // Different last-played colors for red vs black pieces
                let pulse = (sin(animationTime * 2) + 1.0) * 0.15 + 0.15 // Range 0.15 to 0.45
                
                if isRedPiece {
                    // Red piece last played: Brighter red with white tint
                    pieceColor = SIMD4<Float>(
                        min(piece.color.x + pulse * 0.3, 1.0),
                        min(piece.color.y + pulse * 0.2, 0.5),
                        min(piece.color.z + pulse * 0.2, 0.5),
                        alpha
                    )
                } else {
                    // Black piece last played: Lighter gray with blue tint
                    pieceColor = SIMD4<Float>(
                        min(piece.color.x + pulse * 0.6, 0.7),
                        min(piece.color.y + pulse * 0.6, 0.7),
                        min(piece.color.z + pulse * 0.8, 0.9),
                        alpha
                    )
                }
            }
            
            var uniforms = Uniforms(
                modelMatrix: pieceTransform,
                viewMatrix: viewMatrix,
                projectionMatrix: projectionMatrix,
                color: pieceColor,
                lightPosition: SIMD3<Float>(5, 10, 5),
                cameraPosition: eye
            )
            
            renderEncoder.setVertexBuffer(piece.vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
            renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
            renderEncoder.drawIndexedPrimitives(type: .triangle,
                                               indexCount: piece.indexCount,
                                               indexType: .uint16,
                                               indexBuffer: piece.indexBuffer,
                                               indexBufferOffset: 0)
            
            // Draw crown for kings
            if piece.isKing {
                let (vertices, indices) = MeshGenerator.createCone(radius: 0.2, height: 0.3)
                guard let crownVertexBuffer = device.makeBuffer(bytes: vertices,
                                                               length: MemoryLayout<Vertex>.stride * vertices.count,
                                                               options: []),
                      let crownIndexBuffer = device.makeBuffer(bytes: indices,
                                                              length: MemoryLayout<UInt16>.stride * indices.count,
                                                              options: []) else { continue }
                
                let crownTransform = pieceTransform * simd_float4x4(translationX: 0, y: 0.3, z: 0)
                var crownUniforms = Uniforms(
                    modelMatrix: crownTransform,
                    viewMatrix: viewMatrix,
                    projectionMatrix: projectionMatrix,
                    color: SIMD4<Float>(1.0, 0.84, 0.0, alpha),
                    lightPosition: SIMD3<Float>(5, 10, 5),
                    cameraPosition: eye
                )
                
                renderEncoder.setVertexBuffer(crownVertexBuffer, offset: 0, index: 0)
                renderEncoder.setVertexBytes(&crownUniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
                renderEncoder.setFragmentBytes(&crownUniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
                renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                   indexCount: indices.count,
                                                   indexType: .uint16,
                                                   indexBuffer: crownIndexBuffer,
                                                   indexBufferOffset: 0)
            }
        }
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
