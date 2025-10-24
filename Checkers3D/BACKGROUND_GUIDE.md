# 3D Checkers - Background System Guide

## Overview

The game features a beautiful animated background with a gradient sky, stars, and atmospheric effects that enhance the visual experience without distracting from gameplay.

## Background Features

### 🌌 Visual Elements

1. **Gradient Sky**
   - Deep blue top (night sky)
   - Purple horizon (atmospheric glow)
   - Dark purple bottom
   - Smooth transitions between colors

2. **Animated Stars**
   - 3 layers of twinkling stars
   - Subtle movement over time
   - Soft glow effect

3. **Atmospheric Effects**
   - Horizon glow (purple/pink tint)
   - Subtle noise texture
   - Vignette effect (darker at edges)

4. **Dynamic Animation**
   - Time-based star movement
   - Smooth continuous animation
   - 60 FPS rendering

## Technical Implementation

### Architecture

```
GameViewController
    └─> Renderer
        ├─> Background Pipeline
        │   ├─> Background Vertex Shader
        │   └─> Background Fragment Shader
        └─> Game Pipeline
            ├─> Game Vertex Shader
            └─> Game Fragment Shader
```

### Rendering Order

1. **Background** (rendered first, furthest back)
2. Board squares
3. Checker pieces
4. UI elements

This ensures proper depth ordering and prevents z-fighting.

### Shader Pipeline

**Background Vertex Shader (`background_vertex`):**
- Transforms background quad vertices
- Passes UV coordinates to fragment shader
- Passes animation time for effects

**Background Fragment Shader (`background_fragment`):**
- Creates gradient sky
- Generates animated stars
- Adds atmospheric effects
- Applies vignette

## File Structure

### Modified Files

1. **Renderer.swift**
   - Added `backgroundPipelineState` property
   - Added `backgroundVertexBuffer` and `backgroundIndexBuffer`
   - Added `buildBackgroundPipeline()` method
   - Added `createBackground()` method
   - Added `drawBackground()` method
   - Modified `draw()` to render background first

2. **Shaders.metal**
   - Added `BackgroundVertex` struct
   - Added `BackgroundVertexOut` struct
   - Added `BackgroundUniforms` struct
   - Added `background_vertex` shader
   - Added `background_fragment` shader

3. **GameViewController.swift**
   - Updated clear color to match background theme

## Background Rendering Details

### Position & Size

```swift
let size: Float = 50.0  // Large backdrop
let position = simd_float4x4(translationX: 3.5, y: 3.5, z: -20.0)
```

The background is:
- Positioned 20 units behind the board
- Centered on the game board (x: 3.5, y: 3.5)
- Large enough to fill the viewport (50x50 units)

### Color Palette

```swift
topColor    = (0.1, 0.15, 0.35)   // Deep blue
horizonColor = (0.4, 0.25, 0.5)   // Purple
bottomColor = (0.15, 0.1, 0.2)    // Dark purple
starColor   = (1.0, 1.0, 0.9)     // Warm white
glowColor   = (0.5, 0.3, 0.6)     // Pink-purple
```

### Animation System

```metal
// Time-based star animation
float2 pos = fract(starUV + offset + in.time * 0.02);
```

- `time` incremented at ~60 FPS (0.016s per frame)
- Stars move slowly (0.02x speed multiplier)
- Multiple layers for depth effect

## Performance

### Optimizations

1. **Single Quad Rendering**
   - Only 6 vertices rendered (2 triangles)
   - Minimal GPU overhead

2. **Procedural Generation**
   - All effects computed in fragment shader
   - No texture memory required

3. **Efficient Pipeline**
   - Separate pipeline for background
   - No unnecessary state changes

### Performance Metrics

- **GPU Impact:** < 1ms per frame
- **Memory Usage:** < 1 KB (vertex/index buffers)
- **Draw Calls:** +1 per frame

## Customization Guide

### Changing Colors

Edit `background_fragment` in Shaders.metal:

```metal
float3 topColor = float3(0.1, 0.15, 0.35);      // Your color here
float3 horizonColor = float3(0.4, 0.25, 0.5);   // Your color here
float3 bottomColor = float3(0.15, 0.1, 0.2);    // Your color here
```

### Adjusting Star Count

Modify the loop in `background_fragment`:

```metal
for (int i = 0; i < 3; i++) {  // Change 3 to desired count
    // Star rendering code
}
```

**Note:** More stars = higher GPU cost

### Animation Speed

Change the time multiplier:

```metal
float2 pos = fract(starUV + offset + in.time * 0.02);  // Adjust 0.02
```

- Higher = faster movement
- Lower = slower movement
- 0.0 = static (no animation)

### Background Position

Adjust in `drawBackground()` in Renderer.swift:

```swift
let modelMatrix = simd_float4x4(translationX: 3.5, y: 3.5, z: -20.0)
//                                                           ^^^^^ Z position
```

- More negative = further back
- Less negative = closer (may overlap game)

### Star Density

Change the UV multiplier in `background_fragment`:

```metal
float2 starUV = uv * 20.0;  // Higher = more dense, Lower = less dense
```

## Troubleshooting

### Background Not Visible

**Issue:** Background renders but isn't visible

**Solutions:**
1. Check z-position (should be negative, behind board)
2. Verify clear color matches theme
3. Ensure background pipeline is created
4. Check draw order (background first)

### Performance Issues

**Issue:** Frame rate drops with background

**Solutions:**
1. Reduce star count (loop iterations)
2. Simplify gradient (fewer color stops)
3. Remove expensive effects (noise, glow)
4. Check GPU profiler for bottlenecks

### Color Banding

**Issue:** Visible bands in gradient

**Solutions:**
1. Add noise (already implemented)
2. Use dithering technique
3. Increase color precision
4. Use smoother interpolation

### Stars Too Bright/Dim

**Issue:** Stars don't look right

**Solutions:**
```metal
stars += smoothstep(0.1, 0.0, d) * 0.3;  // Adjust 0.3 (brightness)
//                                         Higher = brighter
```

## Best Practices

### Do's ✅

- Keep background simple and non-distracting
- Use subtle animations
- Match color palette with game theme
- Test on various devices
- Profile GPU performance

### Don'ts ❌

- Don't make background too busy
- Don't use high-frequency animations
- Don't add too many effect layers
- Don't use expensive texture lookups
- Don't overlap with game elements

## Advanced Techniques

### Adding Nebula Effect

```metal
// In background_fragment, add:
float nebula = 0.0;
for (int i = 0; i < 2; i++) {
    float2 p = uv * 2.0 + float2(float(i));
    nebula += sin(p.x * 3.0 + in.time * 0.1) * 
              cos(p.y * 3.0 - in.time * 0.1) * 0.1;
}
color += float3(0.3, 0.2, 0.5) * nebula;
```

### Parallax Effect

Modify vertex shader to move background with camera:

```metal
// In background_vertex:
float parallaxFactor = 0.1;
out.position.xy += uniforms.cameraPosition.xy * parallaxFactor;
```

### Time-of-Day Cycle

```metal
// Add to BackgroundUniforms:
float dayTime;  // 0.0 = night, 1.0 = day

// In fragment shader:
float3 dayColor = float3(0.5, 0.7, 1.0);
float3 nightColor = topColor;
color = mix(nightColor, dayColor, uniforms.dayTime);
```

## Integration Examples

### Accessing from GameViewController

```swift
// Change background time speed
renderer.animationTime += customSpeed

// Reset background animation
renderer.animationTime = 0.0
```

### Syncing with Game Events

```swift
// Pulse effect on piece capture
func onPieceCapture() {
    renderer.backgroundPulseIntensity = 1.0
}
```

## Future Enhancements

### Possible Additions

1. **Dynamic Weather**
   - Rain effects
   - Lightning flashes
   - Clouds drifting

2. **Interactive Background**
   - Mouse parallax
   - Touch ripples
   - Camera-reactive

3. **Theme Variations**
   - Day/night cycle
   - Season changes
   - Multiple color schemes

4. **Performance Modes**
   - Low/medium/high quality
   - Static background option
   - Battery-saving mode

## Resources

### Learn More

- [Metal Shading Language Guide](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf)
- [Metal Best Practices](https://developer.apple.com/documentation/metal/metal_sample_code_library)
- [Procedural Generation Techniques](https://thebookofshaders.com/)

### Related Files

- `Renderer.swift` - Background rendering code
- `Shaders.metal` - Background shaders
- `GameViewController.swift` - Setup and configuration

---

**Version:** 1.0  
**Last Updated:** October 2024  
**Compatibility:** iOS 13.0+, Metal 2.0+
