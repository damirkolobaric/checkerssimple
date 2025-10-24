# AI Player Implementation

## Overview
The 3D Checkers game now includes an intelligent AI opponent that plays as the black pieces using the **Minimax algorithm with Alpha-Beta pruning**.

## Features

### 🤖 AI Capabilities
- **Strategic Planning**: Uses minimax algorithm to look ahead multiple moves
- **Alpha-Beta Pruning**: Optimizes search by eliminating unnecessary branches
- **Position Evaluation**: Considers piece value, board position, and king control
- **Capture Priority**: Always captures when possible (follows checkers rules)
- **Multi-Jump Detection**: Handles chain captures correctly

### 🎮 Difficulty Levels

| Level | Search Depth | Description |
|-------|--------------|-------------|
| **Easy** | 2 moves ahead | Makes occasional random moves (30% chance) |
| **Medium** | 4 moves ahead | Balanced strategic play (default) |
| **Hard** | 6 moves ahead | Near-optimal play, very challenging |

### 🎯 Evaluation Criteria

The AI evaluates board positions based on:

1. **Piece Value** (10 points per piece)
   - Regular pieces: 10 points
   - Kings: 30 points (3x value)

2. **Position Bonuses** (up to 14 points)
   - Center control: +2 to +14 points
   - Edge penalty: -3 points
   - Advancement bonus: 0 to +14 points

3. **Strategic Factors**
   - King promotion opportunities
   - Capture chains
   - Board control

## How It Works

### Game Flow
```
1. Player (Red) makes move
   ↓
2. AI (Black) starts thinking
   ↓
3. AI explores possible moves using minimax
   ↓
4. AI selects best move
   ↓
5. AI executes move after 0.5s delay
   ↓
6. Back to Player's turn
```

### Minimax Algorithm
```swift
function minimax(state, depth, alpha, beta, isMaximizing):
    if depth == 0:
        return evaluateBoard(state)
    
    if isMaximizing (AI):
        maxScore = -∞
        for each move:
            score = minimax(newState, depth-1, alpha, beta, false)
            maxScore = max(maxScore, score)
            alpha = max(alpha, score)
            if beta ≤ alpha:
                break  // Alpha-Beta pruning
        return maxScore
    else (Player):
        minScore = +∞
        for each move:
            score = minimax(newState, depth-1, alpha, beta, true)
            minScore = min(minScore, score)
            beta = min(beta, score)
            if beta ≤ alpha:
                break  // Alpha-Beta pruning
        return minScore
```

## UI Controls

### Difficulty Button
- Tap the **"AI: Medium"** button at bottom-right
- Select difficulty: Easy, Medium, or Hard
- Changes take effect immediately

### Turn Indicator
- Shows **"Red's Turn"** when it's your turn
- Shows **"Black's Turn (AI)"** when waiting for AI
- Shows **"AI Thinking..."** while AI calculates

### Reset Button
- Tap **"Reset"** to start a new game
- Resets to red's turn with all pieces restored

## Game Over
- Alert appears when one side has no pieces left
- Shows "You Win!" or "AI Wins!"
- Tap "New Game" to play again

## Implementation Details

### Key Classes

**AIPlayer.swift**
- `getBestMove()` - Main entry point for AI move selection
- `minimax()` - Recursive minimax with alpha-beta pruning
- `evaluateBoard()` - Heuristic evaluation function
- `getAllValidMoves()` - Generates all legal moves
- `getCaptureMoves()` - Finds capture opportunities
- `getRegularMoves()` - Finds non-capture moves

**GameViewController.swift**
- `makeAIMove()` - Triggers AI calculation on background thread
- `getCurrentGameState()` - Converts renderer state to AI format
- `applyAIMove()` - Executes AI's chosen move
- `checkGameOver()` - Detects win/loss conditions

### Performance
- **Easy**: ~0.1 seconds per move
- **Medium**: ~0.5 seconds per move
- **Hard**: ~2-5 seconds per move

AI runs on a background thread to keep UI responsive.

## Strategy Tips

### To Beat the AI:
1. **Control the center** - Central pieces are more valuable
2. **Get kings early** - Kings are 3x more valuable
3. **Force trades when ahead** - Simplify when winning
4. **Avoid edges** - Edge pieces are easier to trap
5. **Plan captures** - Look for multi-jump opportunities

### AI Weaknesses:
- **Easy mode** makes random moves sometimes
- **Medium mode** can be outmaneuvered with tactics
- **Hard mode** is challenging but can be beaten with perfect play

## Future Enhancements

Possible improvements:
- [ ] Opening book for faster early game
- [ ] Endgame database for perfect play
- [ ] Learning from player strategies
- [ ] Multiplayer over network
- [ ] Save/load game state
- [ ] Move hints for player
- [ ] Undo/redo moves

## Technical Notes

### Thread Safety
- AI calculation runs on background thread
- UI updates on main thread only
- Player input disabled during AI's turn

### Memory Management
- Efficient state representation
- Pruning reduces memory usage
- No memory leaks with weak self references

### Game Rules Compliance
- Mandatory captures
- Multi-jump chains
- King promotion
- Direction restrictions
- All standard checkers rules
