# 3D Checkers Game in Swift with Metal

A high-performance 3D checkers game built with Swift and Metal for iOS.

## Features

- **Metal Rendering**: Hardware-accelerated 3D graphics using Metal API
- **Custom Shaders**: Phong lighting model with ambient, diffuse, and specular components
- **3D Board**: Interactive 8x8 checkerboard with proper materials
- **Game Pieces**: Cylindrical red and black pieces with procedural geometry
- **Touch Controls**: Tap to select pieces and move them
- **Turn-based Play**: Alternates between red and black players
- **King Promotion**: Pieces become kings when reaching the opposite end (golden cone crown)
- **Camera Control**: Pan to rotate, pinch to zoom
- **Reset Function**: Button to restart the game at any time
- **Turn Indicator**: Visual display of whose turn it is

## How to Play

1. **Select a Piece**: Tap on your colored piece (red starts first)
2. **Move**: Tap on a valid diagonal square to move
3. **Kings**: When a piece reaches the opposite end, it becomes a king with a golden crown
4. **Camera**: Pan to rotate the camera, pinch to zoom in/out
5. **Reset**: Tap "Reset Game" to start over

## Game Rules

- Pieces move diagonally forward (one square at a time)
- Only dark squares are playable
- Red pieces start from the bottom (rows 0-2)
- Black pieces start from the top (rows 5-7)
- Kings can move both forward and backward
- Regular pieces can only move forward

## Project Structure

```
Checkers3D/
├── AppDelegate.swift          # App entry point
├── GameViewController.swift   # Main game controller with UI and input
├── Renderer.swift             # Metal rendering engine
├── MeshGenerator.swift        # Procedural geometry generation
├── MathUtils.swift            # Matrix math and transformations
├── Shaders.metal              # Vertex and fragment shaders
├── Info.plist                 # App configuration
└── README.md                  # This file
```

## Building the Project

This is a Swift iOS application using Metal. To run:

1. Open Xcode (14.0+)
2. Create a new iOS App project
3. Add all the provided files to your project:
   - `AppDelegate.swift`
   - `GameViewController.swift`
   - `Renderer.swift`
   - `MeshGenerator.swift`
   - `MathUtils.swift`
   - `Shaders.metal`
   - `Info.plist`
4. Build and run on a device or simulator with Metal support (iOS 13.0+)

**Note**: Metal requires a physical device or a Metal-compatible simulator. Some older simulators may not support Metal.

## Technical Details

- **Language**: Swift 5.5+
- **Framework**: Metal, MetalKit
- **Platform**: iOS 13.0+
- **Rendering**: Custom Metal pipeline with vertex/fragment shaders
- **Lighting**: Phong reflection model
- **Geometry**: Procedurally generated meshes (boxes, cylinders, cones)
- **Architecture**: MVC with separated rendering engine

## Metal Rendering Pipeline

1. **Vertex Shader**: Transforms vertices to screen space, calculates normals
2. **Fragment Shader**: Implements Phong lighting with:
   - Ambient lighting (30% strength)
   - Diffuse lighting (directional)
   - Specular highlights (shininess: 32)
3. **Depth Testing**: Proper 3D occlusion with depth buffer

## Future Enhancements

- Jump/capture mechanics with piece removal
- Multi-jump chains
- Forced captures (mandatory jumps)
- Win condition detection and game over screen
- Score tracking and statistics
- AI opponent with minimax algorithm
- Animated piece movements
- Particle effects for captures
- Sound effects and music
- Multiple board themes
- Game history and undo
- Online multiplayer

## Performance

- Metal provides hardware-accelerated rendering
- Efficient vertex/index buffers
- Minimal draw calls with batched rendering
- Smooth 60 FPS on modern iOS devices

## License

MIT License - Feel free to use and modify
