import UIKit
import MetalKit

class GameViewController: UIViewController {
    var metalView: MTKView!
    var renderer: Renderer!
    
    var selectedPieceIndex: Int?
    var currentPlayer: Player = .red
    var aiPlayer = AIPlayer()
    var isAIThinking = false
    
    enum Player {
        case red, black
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMetal()
        setupGestures()
        addControlButtons()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Start background music when view appears
        SoundManager.shared.startBackgroundMusic()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause background music when view disappears
        SoundManager.shared.pauseBackgroundMusic()
    }
    
    func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        
        metalView = MTKView(frame: view.bounds, device: device)
        metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        metalView.clearColor = MTLClearColor(red: 0.12, green: 0.1, blue: 0.18, alpha: 1.0)
        metalView.depthStencilPixelFormat = .depth32Float
        view.addSubview(metalView)
        
        renderer = Renderer(device: device)
        metalView.delegate = renderer
    }
    
    func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        metalView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        metalView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        metalView.addGestureRecognizer(pinchGesture)
    }
    
    func addControlButtons() {
        let resetButton = UIButton(type: .system)
        resetButton.setTitle("Reset", for: .normal)
        resetButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        resetButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.layer.cornerRadius = 8
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.addTarget(self, action: #selector(resetGame), for: .touchUpInside)
        view.addSubview(resetButton)
        
        let difficultyButton = UIButton(type: .system)
        difficultyButton.setTitle("AI: Medium", for: .normal)
        difficultyButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
        difficultyButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        difficultyButton.setTitleColor(.white, for: .normal)
        difficultyButton.layer.cornerRadius = 8
        difficultyButton.translatesAutoresizingMaskIntoConstraints = false
        difficultyButton.addTarget(self, action: #selector(changeDifficulty), for: .touchUpInside)
        difficultyButton.tag = 101
        view.addSubview(difficultyButton)
        
        let soundButton = UIButton(type: .system)
        soundButton.setTitle("🔊", for: .normal)
        soundButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        soundButton.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.8)
        soundButton.layer.cornerRadius = 8
        soundButton.translatesAutoresizingMaskIntoConstraints = false
        soundButton.addTarget(self, action: #selector(toggleSound), for: .touchUpInside)
        soundButton.tag = 102
        view.addSubview(soundButton)
        
        let musicButton = UIButton(type: .system)
        musicButton.setTitle("🎵", for: .normal)
        musicButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        musicButton.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.8)
        musicButton.layer.cornerRadius = 8
        musicButton.translatesAutoresizingMaskIntoConstraints = false
        musicButton.addTarget(self, action: #selector(toggleMusic), for: .touchUpInside)
        musicButton.tag = 103
        view.addSubview(musicButton)
        
        let turnLabel = UILabel()
        turnLabel.text = "Red's Turn"
        turnLabel.textColor = .white
        turnLabel.font = UIFont.systemFont(ofSize: 17)
        turnLabel.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        turnLabel.textAlignment = .center
        turnLabel.layer.cornerRadius = 8
        turnLabel.clipsToBounds = true
        turnLabel.translatesAutoresizingMaskIntoConstraints = false
        turnLabel.tag = 100
        view.addSubview(turnLabel)
        
        NSLayoutConstraint.activate([
            resetButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            resetButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -65),
            resetButton.widthAnchor.constraint(equalToConstant: 60),
            resetButton.heightAnchor.constraint(equalToConstant: 44),
            
            difficultyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            difficultyButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: -40),
            difficultyButton.widthAnchor.constraint(equalToConstant: 80),
            difficultyButton.heightAnchor.constraint(equalToConstant: 44),
            
            soundButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            soundButton.leadingAnchor.constraint(equalTo: difficultyButton.trailingAnchor, constant: 10),
            soundButton.widthAnchor.constraint(equalToConstant: 50),
            soundButton.heightAnchor.constraint(equalToConstant: 44),
            
            musicButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            musicButton.leadingAnchor.constraint(equalTo: soundButton.trailingAnchor, constant: 10),
            musicButton.widthAnchor.constraint(equalToConstant: 50),
            musicButton.heightAnchor.constraint(equalToConstant: 44),
            
            turnLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            turnLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            turnLabel.widthAnchor.constraint(equalToConstant: 200),
            turnLabel.heightAnchor.constraint(equalToConstant: 44),

            difficultyButton.heightAnchor.constraint(equalToConstant: 44),
            
            soundButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            soundButton.leadingAnchor.constraint(equalTo: difficultyButton.trailingAnchor, constant: 10),
            soundButton.widthAnchor.constraint(equalToConstant: 50),
            soundButton.heightAnchor.constraint(equalToConstant: 44),
            
            turnLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            turnLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            turnLabel.widthAnchor.constraint(equalToConstant: 200),
            turnLabel.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc func toggleMusic() {
        let currentEnabled = SoundManager.shared.isMusicEnabled()
        SoundManager.shared.setMusicEnabled(!currentEnabled)
        
        if let button = view.viewWithTag(103) as? UIButton {
            button.setTitle(SoundManager.shared.isMusicEnabled() ? "🎵" : "🔇", for: .normal)
        }
    }
    
    @objc func toggleSound() {
        let currentEnabled = SoundManager.shared.isSoundEnabled()
        SoundManager.shared.setSoundEnabled(!currentEnabled)
        
        if let button = view.viewWithTag(102) as? UIButton {
            button.setTitle(SoundManager.shared.isSoundEnabled() ? "🔊" : "🔇", for: .normal)
        }
        
        // Play feedback if sound was enabled
        if SoundManager.shared.isSoundEnabled() {
            SoundManager.shared.play(.select)
        }
    }
    
    @objc func changeDifficulty() {
        let alert = UIAlertController(title: "AI Difficulty", message: "Choose difficulty level", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Easy", style: .default) { [weak self] _ in
            self?.aiPlayer.difficulty = .easy
            self?.updateDifficultyButton()
        })
        
        alert.addAction(UIAlertAction(title: "Medium", style: .default) { [weak self] _ in
            self?.aiPlayer.difficulty = .medium
            self?.updateDifficultyButton()
        })
        
        alert.addAction(UIAlertAction(title: "Hard", style: .default) { [weak self] _ in
            self?.aiPlayer.difficulty = .hard
            self?.updateDifficultyButton()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    func updateDifficultyButton() {
        if let button = view.viewWithTag(101) as? UIButton {
            let difficultyText: String
            switch aiPlayer.difficulty {
            case .easy: difficultyText = "Easy"
            case .medium: difficultyText = "Medium"
            case .hard: difficultyText = "Hard"
            }
            button.setTitle("AI: \(difficultyText)", for: .normal)
        }
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        // Ignore taps during AI's turn or during animation
        guard !isAIThinking && currentPlayer == .red && !renderer.isAnimating() else { return }
        
        let location = gesture.location(in: metalView)
        
        // Create ray from screen point
        let ray = Picker.rayFromScreenPoint(location,
                                           viewportSize: metalView.bounds.size,
                                           projectionMatrix: renderer.getProjectionMatrix(aspectRatio: Float(metalView.bounds.width / metalView.bounds.height)),
                                           viewMatrix: renderer.getViewMatrix())
        
        // Check pieces first
        var closestPieceIndex: Int?
        var closestPieceDistance: Float = Float.infinity
        
        for (index, piece) in renderer.pieces.enumerated() {
            let sphere = BoundingSphere(center: SIMD3<Float>(piece.transform.columns.3.x,
                                                             piece.transform.columns.3.y,
                                                             piece.transform.columns.3.z),
                                       radius: 0.5)
            
            if let distance = sphere.intersects(ray: ray) {
                if distance < closestPieceDistance {
                    closestPieceDistance = distance
                    closestPieceIndex = index
                }
            }
        }
        
        if let pieceIndex = closestPieceIndex {
            // Clicked on a piece
            if selectedPieceIndex == pieceIndex {
                // Deselect
                selectedPieceIndex = nil
                renderer.selectedPieceIndex = nil
                SoundManager.shared.play(.select)
            } else {
                let piece = renderer.pieces[pieceIndex]
                let isRed = piece.color.x > 0.5
                
                if (isRed && currentPlayer == .red) || (!isRed && currentPlayer == .black) {
                    selectedPieceIndex = pieceIndex
                    renderer.selectedPieceIndex = pieceIndex
                    SoundManager.shared.play(.select)
                } else {
                    SoundManager.shared.play(.invalid)
                }
            }
        } else {
            // Check board squares
            var closestSquare: (Int, Int)?
            var closestSquareDistance: Float = Float.infinity
            
            for row in 0..<8 {
                for col in 0..<8 {
                    let squareCenter = SIMD3<Float>(Float(col), -0.1, Float(row))
                    let bounds = BoundingBox(min: squareCenter - SIMD3<Float>(0.5, 0.1, 0.5),
                                            max: squareCenter + SIMD3<Float>(0.5, 0.1, 0.5))
                    
                    if let distance = bounds.intersects(ray: ray) {
                        if distance < closestSquareDistance {
                            closestSquareDistance = distance
                            closestSquare = (row, col)
                        }
                    }
                }
            }
            
            if let square = closestSquare, let selectedIndex = selectedPieceIndex {
                // Try to move selected piece
                if isValidMove(pieceIndex: selectedIndex, to: square) {
                    // Get current position
                    let currentPos = renderer.pieces[selectedIndex].transform.columns.3
                    let currentRow = Int(round(currentPos.z))
                    let currentCol = Int(round(currentPos.x))
                    
                    // Check if this is a capture move
                    let capturedIndex = getCapturedPieceIndex(from: (currentRow, currentCol), to: square)
                    if let capIndex = capturedIndex {
                        // Animate the captured piece
                        renderer.capturePiece(at: capIndex)
                        SoundManager.shared.play(.capture)
                    } else {
                        SoundManager.shared.play(.move)
                    }
                    
                    // Move the piece
                    renderer.movePiece(at: selectedIndex, to: square)
                    
                    // Check if piece becomes king
                    let piece = renderer.pieces[selectedIndex]
                    let isRed = piece.color.x > 0.5
                    if (isRed && square.0 == 7) || (!isRed && square.0 == 0) {
                        if !piece.isKing {
                            SoundManager.shared.playDelayed(.king, delay: 0.35)
                        }
                    }
                    
                    // Update highlights
                    renderer.lastPlayedPieceIndex = selectedIndex
                    selectedPieceIndex = nil
                    renderer.selectedPieceIndex = nil
                    
                    // Wait for animations to complete before switching turn
                    let delay = capturedIndex != nil ? 0.45 : 0.35
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                        guard let self = self else { return }
                        
                        self.currentPlayer = self.currentPlayer == .red ? .black : .red
                        self.updateTurnLabel()
                        self.checkGameOver()
                        
                        // Trigger AI move after player moves
                        if self.currentPlayer == .black {
                            self.makeAIMove()
                        }
                    }
                } else {
                    SoundManager.shared.play(.invalid)
                }
            }
        }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: metalView)
        renderer.cameraRotation += Float(translation.x) * 0.01
        gesture.setTranslation(.zero, in: metalView)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        let scale = Float(gesture.scale)
        renderer.cameraPosition.y /= scale
        renderer.cameraPosition.y = max(3, min(15, renderer.cameraPosition.y))
        gesture.scale = 1.0
    }
    
    @objc func resetGame() {
        renderer.pieces.removeAll()
        renderer.createPieces()
        currentPlayer = .red
        selectedPieceIndex = nil
        renderer.selectedPieceIndex = nil
        renderer.lastPlayedPieceIndex = nil
        isAIThinking = false
        
        // Reset effects
        renderer.victoryEffectActive = false
        renderer.defeatEffectActive = false
        renderer.victoryEffectTime = 0
        
        // Reset camera to starting position with intro animation
        renderer.startCameraIntro()
        
        updateTurnLabel()
    }
    
    func findPieceAt(row: Int, col: Int) -> Int? {
        for (index, piece) in renderer.pieces.enumerated() {
            let position = piece.transform.columns.3
            let pieceRow = Int(round(position.z))
            let pieceCol = Int(round(position.x))
            
            if pieceRow == row && pieceCol == col {
                return index
            }
        }
        return nil
    }
    
    func isValidMove(pieceIndex: Int, to position: (Int, Int)) -> Bool {
        let piece = renderer.pieces[pieceIndex]
        let currentPos = piece.transform.columns.3
        let currentRow = Int(round(currentPos.z))
        let currentCol = Int(round(currentPos.x))
        
        let rowDiff = position.0 - currentRow
        let colDiff = position.1 - currentCol
        let absRowDiff = abs(rowDiff)
        let absColDiff = abs(colDiff)
        
        // Must move diagonally
        guard absColDiff == absRowDiff else { return false }
        
        // Check if destination is occupied
        if findPieceAt(row: position.0, col: position.1) != nil {
            return false
        }
        
        let isRed = piece.color.x > 0.5
        
        // Check for jump move (2 squares)
        if absRowDiff == 2 && absColDiff == 2 {
            // Check direction for non-kings
            if !piece.isKing {
                if isRed && rowDiff != 2 { return false }
                if !isRed && rowDiff != -2 { return false }
            }
            
            // Check if there's an enemy piece to jump over
            let middleRow = currentRow + rowDiff / 2
            let middleCol = currentCol + colDiff / 2
            
            if let middlePieceIndex = findPieceAt(row: middleRow, col: middleCol) {
                let middlePiece = renderer.pieces[middlePieceIndex]
                let middleIsRed = middlePiece.color.x > 0.5
                
                // Can only jump over enemy pieces
                return middleIsRed != isRed
            }
            
            return false
        }
        
        // Regular move (1 square)
        if absRowDiff == 1 && absColDiff == 1 {
            if piece.isKing {
                // Kings can move both directions
                return true
            } else {
                // Regular pieces move forward only
                if isRed && rowDiff == 1 { return true }
                if !isRed && rowDiff == -1 { return true }
            }
        }
        
        return false
    }
    
    func getCapturedPieceIndex(from: (Int, Int), to: (Int, Int)) -> Int? {
        let rowDiff = to.0 - from.0
        let colDiff = to.1 - from.1
        
        // Only for jump moves
        if abs(rowDiff) == 2 && abs(colDiff) == 2 {
            let middleRow = from.0 + rowDiff / 2
            let middleCol = from.1 + colDiff / 2
            return findPieceAt(row: middleRow, col: middleCol)
        }
        
        return nil
    }
    
    func updateTurnLabel() {
        if let label = view.viewWithTag(100) as? UILabel {
            if isAIThinking {
                label.text = "AI Thinking..."
            } else {
                label.text = currentPlayer == .red ? "Red's Turn" : "Black's Turn (AI)"
            }
        }
    }
    
    func makeAIMove() {
        guard currentPlayer == .black && !isAIThinking else { return }
        
        isAIThinking = true
        updateTurnLabel()
        
        // Run AI on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Convert game state
            let gameState = self.getCurrentGameState()
            
            // Get AI move
            if let aiMove = self.aiPlayer.getBestMove(gameState: gameState) {
                // Apply move on main thread after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.applyAIMove(aiMove)
                }
            } else {
                // No valid moves - game over
                DispatchQueue.main.async {
                    self.isAIThinking = false
                    self.showGameOver(winner: .red)
                }
            }
        }
    }
    
    func getCurrentGameState() -> AIPlayer.GameState {
        var pieces: [(row: Int, col: Int, isKing: Bool, isRed: Bool)] = []
        
        for piece in renderer.pieces {
            let pos = piece.transform.columns.3
            let row = Int(round(pos.z))
            let col = Int(round(pos.x))
            let isKing = piece.isKing
            let isRed = piece.color.x > 0.5
            
            pieces.append((row: row, col: col, isKing: isKing, isRed: isRed))
        }
        
        return AIPlayer.GameState(pieces: pieces)
    }
    
    func applyAIMove(_ move: AIPlayer.Move) {
        // Find the piece to move
        guard let pieceIndex = renderer.pieces.firstIndex(where: {
            let pos = $0.transform.columns.3
            return Int(round(pos.z)) == move.fromRow && Int(round(pos.x)) == move.fromCol
        }) else { return }
        
        // Animate captured pieces
        for (capturedRow, capturedCol) in move.capturedPieces {
            if let capturedIndex = renderer.pieces.firstIndex(where: {
                let pos = $0.transform.columns.3
                return Int(round(pos.z)) == capturedRow && Int(round(pos.x)) == capturedCol
            }) {
                renderer.capturePiece(at: capturedIndex)
            }
        }
        
        // Play appropriate sound
        if !move.capturedPieces.isEmpty {
            SoundManager.shared.play(.capture)
        } else {
            SoundManager.shared.play(.move)
        }
        
        // Move the piece (starts animation)
        renderer.movePiece(at: pieceIndex, to: (move.toRow, move.toCol))
        
        // Highlight AI's last move
        renderer.lastPlayedPieceIndex = pieceIndex
        
        // Check for king promotion
        if move.becomesKing {
            renderer.pieces[pieceIndex].isKing = true
            SoundManager.shared.playDelayed(.king, delay: 0.35)
        }
        
        // Wait for both move and capture animations to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.currentPlayer = .red
            self?.isAIThinking = false
            self?.updateTurnLabel()
            
            // Check for game over
            self?.checkGameOver()
        }
    }
    
    func showGameOver(winner: Player) {
        if winner == .red {
            SoundManager.shared.play(.victory)
            renderer.startVictoryEffect()
        } else {
            SoundManager.shared.play(.defeat)
            renderer.startDefeatEffect()
        }
        
        let message = winner == .red ? "🎉 You Win! 🎉" : "😔 AI Wins 😔"
        let alert = UIAlertController(title: "Game Over", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "New Game", style: .default) { [weak self] _ in
            self?.resetGame()
        })
        
        // Show alert after a delay to let the effect play
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.present(alert, animated: true)
        }
    }
    
    func checkGameOver() {
        let redPieces = renderer.pieces.filter { $0.color.x > 0.5 }
        let blackPieces = renderer.pieces.filter { $0.color.x < 0.5 }
        
        if redPieces.isEmpty {
            showGameOver(winner: .black)
        } else if blackPieces.isEmpty {
            showGameOver(winner: .red)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
