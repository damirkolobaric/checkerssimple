import Foundation
import simd

class AIPlayer {
    enum Difficulty {
        case easy      // Depth 2, random moves
        case medium    // Depth 4, strategic
        case hard      // Depth 6, optimal
        
        var searchDepth: Int {
            switch self {
            case .easy: return 2
            case .medium: return 4
            case .hard: return 6
            }
        }
    }
    
    var difficulty: Difficulty = .medium
    
    struct Move {
        let fromRow: Int
        let fromCol: Int
        let toRow: Int
        let toCol: Int
        var capturedPieces: [(Int, Int)] = []
        var becomesKing: Bool = false
    }
    
    struct GameState {
        var pieces: [(row: Int, col: Int, isKing: Bool, isRed: Bool)]
        
        init(pieces: [(row: Int, col: Int, isKing: Bool, isRed: Bool)]) {
            self.pieces = pieces
        }
        
        func pieceAt(row: Int, col: Int) -> (isKing: Bool, isRed: Bool)? {
            guard let piece = pieces.first(where: { $0.row == row && $0.col == col }) else {
                return nil
            }
            return (piece.isKing, piece.isRed)
        }
        
        mutating func applyMove(_ move: Move) {
            // Remove captured pieces
            pieces.removeAll { piece in
                move.capturedPieces.contains { $0.0 == piece.row && $0.1 == piece.col }
            }
            
            // Move piece
            if let index = pieces.firstIndex(where: { $0.row == move.fromRow && $0.col == move.fromCol }) {
                pieces[index].row = move.toRow
                pieces[index].col = move.toCol
                if move.becomesKing {
                    pieces[index].isKing = true
                }
            }
        }
    }
    
    func getBestMove(gameState: GameState) -> Move? {
        let moves = getAllValidMoves(for: gameState, isRed: false)
        
        guard !moves.isEmpty else { return nil }
        
        // Easy mode - just pick a random move
        if difficulty == .easy && arc4random_uniform(100) < 30 {
            return moves.randomElement()
        }
        
        var bestMove: Move?
        var bestScore = Int.min
        
        for move in moves {
            var newState = gameState
            newState.applyMove(move)
            
            let score = minimax(state: newState, depth: difficulty.searchDepth - 1, 
                              alpha: Int.min, beta: Int.max, isMaximizing: false)
            
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        
        return bestMove
    }
    
    private func minimax(state: GameState, depth: Int, alpha: Int, beta: Int, isMaximizing: Bool) -> Int {
        if depth == 0 {
            return evaluateBoard(state)
        }
        
        let moves = getAllValidMoves(for: state, isRed: isMaximizing)
        
        if moves.isEmpty {
            // Game over - return extreme score
            return isMaximizing ? Int.min + 1000 : Int.max - 1000
        }
        
        var alpha = alpha
        var beta = beta
        
        if isMaximizing {
            var maxScore = Int.min
            for move in moves {
                var newState = state
                newState.applyMove(move)
                let score = minimax(state: newState, depth: depth - 1, alpha: alpha, beta: beta, isMaximizing: false)
                maxScore = max(maxScore, score)
                alpha = max(alpha, score)
                if beta <= alpha {
                    break // Beta cutoff
                }
            }
            return maxScore
        } else {
            var minScore = Int.max
            for move in moves {
                var newState = state
                newState.applyMove(move)
                let score = minimax(state: newState, depth: depth - 1, alpha: alpha, beta: beta, isMaximizing: true)
                minScore = min(minScore, score)
                beta = min(beta, score)
                if beta <= alpha {
                    break // Alpha cutoff
                }
            }
            return minScore
        }
    }
    
    private func evaluateBoard(_ state: GameState) -> Int {
        var score = 0
        
        for piece in state.pieces {
            let pieceValue = piece.isKing ? 30 : 10
            let positionBonus = evaluatePosition(row: piece.row, col: piece.col, isRed: piece.isRed)
            
            if piece.isRed {
                score -= (pieceValue + positionBonus)
            } else {
                score += (pieceValue + positionBonus)
            }
        }
        
        return score
    }
    
    private func evaluatePosition(row: Int, col: Int, isRed: Bool) -> Int {
        var bonus = 0
        
        // Center control
        let distFromCenter = abs(col - 3) + abs(col - 4)
        bonus += (7 - distFromCenter) * 2
        
        // Edge penalty
        if col == 0 || col == 7 {
            bonus -= 3
        }
        
        // Advancement bonus
        if isRed {
            bonus += row * 2  // Red moves down
        } else {
            bonus += (7 - row) * 2  // Black moves up
        }
        
        return bonus
    }
    
    private func getAllValidMoves(for state: GameState, isRed: Bool) -> [Move] {
        var allMoves: [Move] = []
        var captureMovesExist = false
        
        // First check if any capture moves exist
        for piece in state.pieces where piece.isRed == isRed {
            let captureMoves = getCaptureMoves(for: piece, in: state)
            if !captureMoves.isEmpty {
                captureMovesExist = true
                allMoves.append(contentsOf: captureMoves)
            }
        }
        
        // If no captures, get regular moves
        if !captureMovesExist {
            for piece in state.pieces where piece.isRed == isRed {
                allMoves.append(contentsOf: getRegularMoves(for: piece, in: state))
            }
        }
        
        return allMoves
    }
    
    private func getCaptureMoves(for piece: (row: Int, col: Int, isKing: Bool, isRed: Bool), 
                                 in state: GameState) -> [Move] {
        var moves: [Move] = []
        let directions: [(Int, Int)]
        
        if piece.isKing {
            directions = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        } else if piece.isRed {
            directions = [(1, -1), (1, 1)]
        } else {
            directions = [(-1, -1), (-1, 1)]
        }
        
        for (dRow, dCol) in directions {
            let jumpRow = piece.row + dRow
            let jumpCol = piece.col + dCol
            let landRow = piece.row + dRow * 2
            let landCol = piece.col + dCol * 2
            
            // Check if there's an enemy piece to jump
            if isValidPosition(jumpRow, jumpCol),
               isValidPosition(landRow, landCol),
               let jumpPiece = state.pieceAt(row: jumpRow, col: jumpCol),
               jumpPiece.isRed != piece.isRed,
               state.pieceAt(row: landRow, col: landCol) == nil {
                
                let becomesKing = !piece.isKing && ((piece.isRed && landRow == 7) || (!piece.isRed && landRow == 0))
                
                var move = Move(fromRow: piece.row, fromCol: piece.col,
                              toRow: landRow, toCol: landCol,
                              capturedPieces: [(jumpRow, jumpCol)],
                              becomesKing: becomesKing)
                
                // Check for multi-jumps
                var newState = state
                newState.applyMove(move)
                let multiJumps = getCaptureMoves(for: (landRow, landCol, piece.isKing || becomesKing, piece.isRed), in: newState)
                
                if !multiJumps.isEmpty {
                    // Continue the jump chain
                    for jump in multiJumps {
                        var chainedMove = Move(fromRow: piece.row, fromCol: piece.col,
                                             toRow: jump.toRow, toCol: jump.toCol,
                                             capturedPieces: move.capturedPieces + jump.capturedPieces,
                                             becomesKing: jump.becomesKing)
                        moves.append(chainedMove)
                    }
                } else {
                    moves.append(move)
                }
            }
        }
        
        return moves
    }
    
    private func getRegularMoves(for piece: (row: Int, col: Int, isKing: Bool, isRed: Bool),
                                 in state: GameState) -> [Move] {
        var moves: [Move] = []
        let directions: [(Int, Int)]
        
        if piece.isKing {
            directions = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
        } else if piece.isRed {
            directions = [(1, -1), (1, 1)]
        } else {
            directions = [(-1, -1), (-1, 1)]
        }
        
        for (dRow, dCol) in directions {
            let newRow = piece.row + dRow
            let newCol = piece.col + dCol
            
            if isValidPosition(newRow, newCol),
               state.pieceAt(row: newRow, col: newCol) == nil {
                
                let becomesKing = !piece.isKing && ((piece.isRed && newRow == 7) || (!piece.isRed && newRow == 0))
                
                let move = Move(fromRow: piece.row, fromCol: piece.col,
                              toRow: newRow, toCol: newCol,
                              becomesKing: becomesKing)
                moves.append(move)
            }
        }
        
        return moves
    }
    
    private func isValidPosition(_ row: Int, _ col: Int) -> Bool {
        return row >= 0 && row < 8 && col >= 0 && col < 8
    }
}
