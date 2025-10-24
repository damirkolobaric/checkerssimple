# 3D Object Picking in Metal - Quick Reference

## Overview
This guide shows how to detect clicks/taps on 3D objects rendered with Metal.

## Core Concept: Raycasting

When you click on the screen:
1. **Convert screen coordinates to a 3D ray** (origin + direction)
2. **Test which 3D objects the ray intersects**
3. **Select the closest intersection**

---

## Method 1: Raycasting with Bounding Sphere (FASTEST)

**Best for**: Real-time interaction, many objects, approximate selection

```swift
// 1. Create a ray from screen point
let ray = Picker.rayFromScreenPoint(
    tapLocation,
    viewportSize: view.bounds.size,
    projectionMatrix: projectionMatrix,
    viewMatrix: viewMatrix
)

// 2. Create bounding sphere for your object
let sphere = BoundingSphere(
    center: objectPosition,  // SIMD3<Float>
    radius: 0.5             // Approximate size
)

// 3. Test intersection
if let distance = sphere.intersects(ray: ray) {
    print("Hit object at distance: \(distance)")
}
```

**Pros**: Very fast, simple
**Cons**: Less accurate (sphere approximation)

---

## Method 2: Raycasting with Bounding Box (ACCURATE)

**Best for**: Rectangular objects, better precision

```swift
// Create bounding box
let bounds = BoundingBox(
    min: SIMD3<Float>(-0.5, -0.5, -0.5),
    max: SIMD3<Float>(0.5, 0.5, 0.5)
)

// Test intersection
if let distance = bounds.intersects(ray: ray) {
    print("Hit object at distance: \(distance)")
}
```

**Pros**: More accurate than sphere for boxes
**Cons**: Still an approximation

---

## Method 3: Triangle-Level Raycasting (MOST ACCURATE)

**Best for**: Precise selection, complex meshes

```swift
// Test each triangle in the mesh
for i in stride(from: 0, to: indices.count, by: 3) {
    let v0 = transformedVertices[indices[i]]
    let v1 = transformedVertices[indices[i+1]]
    let v2 = transformedVertices[indices[i+2]]
    
    if let distance = Picker.intersectTriangle(
        ray: ray, 
        v0: v0, 
        v1: v1, 
        v2: v2
    ) {
        print("Hit triangle at distance: \(distance)")
    }
}
```

**Pros**: Pixel-perfect accuracy
**Cons**: Slower for complex meshes

---

## Complete Example: Tap to Select

```swift
@objc func handleTap(_ gesture: UITapGestureRecognizer) {
    let location = gesture.location(in: metalView)
    
    // 1. Create ray
    let ray = Picker.rayFromScreenPoint(
        location,
        viewportSize: metalView.bounds.size,
        projectionMatrix: getProjectionMatrix(),
        viewMatrix: getViewMatrix()
    )
    
    // 2. Find closest object
    var closestIndex: Int?
    var closestDistance: Float = .infinity
    
    for (index, object) in objects.enumerated() {
        let sphere = BoundingSphere(
            center: object.position,
            radius: object.radius
        )
        
        if let distance = sphere.intersects(ray: ray) {
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }
    }
    
    // 3. Handle selection
    if let index = closestIndex {
        print("Selected object \(index)")
        selectedObject = objects[index]
    }
}
```

---

## Key Functions

### Create Ray from Screen Point
```swift
let ray = Picker.rayFromScreenPoint(
    screenPoint,      // CGPoint: tap location
    viewportSize,     // CGSize: view bounds
    projectionMatrix, // simd_float4x4
    viewMatrix        // simd_float4x4
)
```

### Test Sphere Intersection
```swift
let sphere = BoundingSphere(center: pos, radius: r)
if let distance = sphere.intersects(ray: ray) {
    // Hit at distance
}
```

### Test Box Intersection
```swift
let box = BoundingBox(min: minPoint, max: maxPoint)
if let distance = box.intersects(ray: ray) {
    // Hit at distance
}
```

### Test Triangle Intersection
```swift
if let distance = Picker.intersectTriangle(
    ray: ray, 
    v0: vertex0, 
    v1: vertex1, 
    v2: vertex2
) {
    // Hit at distance
}
```

---

## Advanced Techniques

### 1. Multi-Object Selection
```swift
// Always select closest object
var closest: (index: Int, distance: Float)?

for (i, obj) in objects.enumerated() {
    if let dist = testIntersection(ray, obj) {
        if closest == nil || dist < closest!.distance {
            closest = (i, dist)
        }
    }
}

if let hit = closest {
    selectObject(at: hit.index)
}
```

### 2. Hover Detection
```swift
var hoveredObject: Int?

func handleMouseMove(_ location: CGPoint) {
    let ray = createRay(from: location)
    hoveredObject = findClosestObject(ray: ray)
    updateCursor(hovered: hoveredObject != nil)
}
```

### 3. Get World Position from Screen
```swift
func worldPosition(from screen: CGPoint, onPlaneY y: Float) -> SIMD3<Float>? {
    let ray = createRay(from: screen)
    
    // Intersect with plane Y = y
    let t = (y - ray.origin.y) / ray.direction.y
    
    if t > 0 {
        return ray.origin + t * ray.direction
    }
    return nil
}
```

### 4. Drag Objects
```swift
var draggedObject: Int?
var dragOffset: SIMD3<Float> = .zero

func startDrag(at point: CGPoint) {
    if let obj = findObject(at: point) {
        draggedObject = obj.index
        dragOffset = obj.position - worldPosition(from: point)!
    }
}

func updateDrag(to point: CGPoint) {
    guard let index = draggedObject else { return }
    if let worldPos = worldPosition(from: point) {
        objects[index].position = worldPos + dragOffset
    }
}

func endDrag() {
    draggedObject = nil
}
```

---

## Performance Tips

1. **Use Bounding Volumes First**: Test cheap bounding sphere/box before expensive triangle tests
2. **Spatial Partitioning**: Use octree/BVH for scenes with many objects
3. **Early Exit**: Return as soon as you find a hit (if you don't need the closest)
4. **Cache Matrices**: Don't recreate projection/view matrices every frame

---

## Common Pitfalls

❌ **Wrong**: Testing objects in wrong coordinate space
```swift
// Don't use model-space positions
let sphere = BoundingSphere(center: vertex.position, ...)
```

✅ **Correct**: Transform to world space first
```swift
let worldPos = transform * SIMD4<Float>(vertex.position, 1.0)
let sphere = BoundingSphere(center: SIMD3(worldPos), ...)
```

❌ **Wrong**: Not checking distance
```swift
if sphere.intersects(ray: ray) != nil {
    select(object)  // Might not be closest!
}
```

✅ **Correct**: Always select closest
```swift
if let dist = sphere.intersects(ray: ray) {
    if dist < closestDistance {
        closestDistance = dist
        closestObject = object
    }
}
```

---

## Summary

| Method | Speed | Accuracy | Use Case |
|--------|-------|----------|----------|
| Bounding Sphere | ⚡⚡⚡ | ⭐ | Many objects, rough selection |
| Bounding Box | ⚡⚡ | ⭐⭐ | Box-like objects |
| Triangle Ray | ⚡ | ⭐⭐⭐ | Precise selection, few objects |

**Recommended**: Start with bounding volumes, add triangle tests if needed.
