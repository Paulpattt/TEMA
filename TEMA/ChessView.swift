import SwiftUI

// Modèle représentant une pièce d'échecs
struct ChessPiece: Identifiable, Equatable {
    let id = UUID()
    let type: PieceType
    let color: PieceColor
    var position: Position
    var hasMoved: Bool = false
    
    static func == (lhs: ChessPiece, rhs: ChessPiece) -> Bool {
        lhs.id == rhs.id
    }
}

// Types de pièces
enum PieceType: String {
    case pawn, rook, knight, bishop, queen, king
    
    var symbol: String {
        switch self {
        case .pawn: return "♟"
        case .rook: return "♜"
        case .knight: return "♞"
        case .bishop: return "♝"
        case .queen: return "♛"
        case .king: return "♚"
        }
    }
}

// Couleurs des pièces
enum PieceColor: String {
    case white, black
    
    var isWhite: Bool {
        self == .white
    }
}

// Position sur l'échiquier
struct Position: Equatable, Hashable {
    let x: Int
    let y: Int
    
    static func == (lhs: Position, rhs: Position) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
}

// Classe pour gérer l'état du jeu
class ChessGame: ObservableObject {
    @Published var pieces: [ChessPiece] = []
    @Published var currentPlayer: PieceColor = .white
    @Published var selectedPiece: ChessPiece? = nil
    @Published var possibleMoves: [Position] = []
    @Published var capturedPieces: [ChessPiece] = []
    @Published var gameStatus: GameStatus = .inProgress
    
    enum GameStatus {
        case inProgress, check, checkmate, stalemate
    }
    
    init() {
        setupBoard()
    }
    
    func setupBoard() {
        pieces = []
        currentPlayer = .white
        selectedPiece = nil
        possibleMoves = []
        capturedPieces = []
        gameStatus = .inProgress
        
        // Ajouter les pions
        for i in 0..<8 {
            pieces.append(ChessPiece(type: .pawn, color: .white, position: Position(x: i, y: 6)))
            pieces.append(ChessPiece(type: .pawn, color: .black, position: Position(x: i, y: 1)))
        }
        
        // Ajouter les tours
        pieces.append(ChessPiece(type: .rook, color: .white, position: Position(x: 0, y: 7)))
        pieces.append(ChessPiece(type: .rook, color: .white, position: Position(x: 7, y: 7)))
        pieces.append(ChessPiece(type: .rook, color: .black, position: Position(x: 0, y: 0)))
        pieces.append(ChessPiece(type: .rook, color: .black, position: Position(x: 7, y: 0)))
        
        // Ajouter les cavaliers
        pieces.append(ChessPiece(type: .knight, color: .white, position: Position(x: 1, y: 7)))
        pieces.append(ChessPiece(type: .knight, color: .white, position: Position(x: 6, y: 7)))
        pieces.append(ChessPiece(type: .knight, color: .black, position: Position(x: 1, y: 0)))
        pieces.append(ChessPiece(type: .knight, color: .black, position: Position(x: 6, y: 0)))
        
        // Ajouter les fous
        pieces.append(ChessPiece(type: .bishop, color: .white, position: Position(x: 2, y: 7)))
        pieces.append(ChessPiece(type: .bishop, color: .white, position: Position(x: 5, y: 7)))
        pieces.append(ChessPiece(type: .bishop, color: .black, position: Position(x: 2, y: 0)))
        pieces.append(ChessPiece(type: .bishop, color: .black, position: Position(x: 5, y: 0)))
        
        // Ajouter les dames
        pieces.append(ChessPiece(type: .queen, color: .white, position: Position(x: 3, y: 7)))
        pieces.append(ChessPiece(type: .queen, color: .black, position: Position(x: 3, y: 0)))
        
        // Ajouter les rois
        pieces.append(ChessPiece(type: .king, color: .white, position: Position(x: 4, y: 7)))
        pieces.append(ChessPiece(type: .king, color: .black, position: Position(x: 4, y: 0)))
    }
    
    func getPiece(at position: Position) -> ChessPiece? {
        pieces.first { $0.position == position }
    }
    
    func selectPiece(_ piece: ChessPiece) {
        if piece.color == currentPlayer {
            selectedPiece = piece
            possibleMoves = calculatePossibleMoves(for: piece)
        }
    }
    
    func movePiece(to position: Position) {
        guard let piece = selectedPiece, possibleMoves.contains(position) else { return }
        
        // Vérifier si une pièce adverse se trouve à la position cible
        if let capturedPiece = getPiece(at: position) {
            capturedPieces.append(capturedPiece)
            pieces.removeAll { $0.id == capturedPiece.id }
        }
        
        // Mettre à jour la position de la pièce
        if let index = pieces.firstIndex(where: { $0.id == piece.id }) {
            pieces[index].position = position
            pieces[index].hasMoved = true
        }
        
        // Changer de joueur
        currentPlayer = currentPlayer == .white ? .black : .white
        
        // Réinitialiser la sélection
        selectedPiece = nil
        possibleMoves = []
        
        // Vérifier l'état du jeu
        checkGameStatus()
    }
    
    func calculatePossibleMoves(for piece: ChessPiece) -> [Position] {
        var moves: [Position] = []
        
        switch piece.type {
        case .pawn:
            let direction = piece.color.isWhite ? -1 : 1
            let frontPosition = Position(x: piece.position.x, y: piece.position.y + direction)
            
            // Mouvement vers l'avant
            if isPositionValid(frontPosition) && getPiece(at: frontPosition) == nil {
                moves.append(frontPosition)
                
                // Double mouvement au premier coup
                if !piece.hasMoved {
                    let doublePosition = Position(x: piece.position.x, y: piece.position.y + 2 * direction)
                    if isPositionValid(doublePosition) && getPiece(at: doublePosition) == nil {
                        moves.append(doublePosition)
                    }
                }
            }
            
            // Captures en diagonale
            let diagonalPositions = [
                Position(x: piece.position.x - 1, y: piece.position.y + direction),
                Position(x: piece.position.x + 1, y: piece.position.y + direction)
            ]
            
            for pos in diagonalPositions {
                if isPositionValid(pos), let targetPiece = getPiece(at: pos), targetPiece.color != piece.color {
                    moves.append(pos)
                }
            }
            
        case .rook:
            // Mouvements horizontaux et verticaux
            let directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]
            
            for (dx, dy) in directions {
                var x = piece.position.x + dx
                var y = piece.position.y + dy
                
                while isPositionValid(Position(x: x, y: y)) {
                    let pos = Position(x: x, y: y)
                    if let targetPiece = getPiece(at: pos) {
                        if targetPiece.color != piece.color {
                            moves.append(pos)
                        }
                        break
                    }
                    moves.append(pos)
                    x += dx
                    y += dy
                }
            }
            
        case .knight:
            // Mouvements en L
            let knightMoves = [
                (1, 2), (2, 1), (2, -1), (1, -2),
                (-1, -2), (-2, -1), (-2, 1), (-1, 2)
            ]
            
            for (dx, dy) in knightMoves {
                let pos = Position(x: piece.position.x + dx, y: piece.position.y + dy)
                if isPositionValid(pos) {
                    if let targetPiece = getPiece(at: pos) {
                        if targetPiece.color != piece.color {
                            moves.append(pos)
                        }
                    } else {
                        moves.append(pos)
                    }
                }
            }
            
        case .bishop:
            // Mouvements diagonaux
            let directions = [(1, 1), (1, -1), (-1, -1), (-1, 1)]
            
            for (dx, dy) in directions {
                var x = piece.position.x + dx
                var y = piece.position.y + dy
                
                while isPositionValid(Position(x: x, y: y)) {
                    let pos = Position(x: x, y: y)
                    if let targetPiece = getPiece(at: pos) {
                        if targetPiece.color != piece.color {
                            moves.append(pos)
                        }
                        break
                    }
                    moves.append(pos)
                    x += dx
                    y += dy
                }
            }
            
        case .queen:
            // Combinaison des mouvements de la tour et du fou
            let directions = [
                (0, 1), (1, 0), (0, -1), (-1, 0),
                (1, 1), (1, -1), (-1, -1), (-1, 1)
            ]
            
            for (dx, dy) in directions {
                var x = piece.position.x + dx
                var y = piece.position.y + dy
                
                while isPositionValid(Position(x: x, y: y)) {
                    let pos = Position(x: x, y: y)
                    if let targetPiece = getPiece(at: pos) {
                        if targetPiece.color != piece.color {
                            moves.append(pos)
                        }
                        break
                    }
                    moves.append(pos)
                    x += dx
                    y += dy
                }
            }
            
        case .king:
            // Mouvements du roi (une case dans toutes les directions)
            let kingMoves = [
                (0, 1), (1, 1), (1, 0), (1, -1),
                (0, -1), (-1, -1), (-1, 0), (-1, 1)
            ]
            
            for (dx, dy) in kingMoves {
                let pos = Position(x: piece.position.x + dx, y: piece.position.y + dy)
                if isPositionValid(pos) {
                    if let targetPiece = getPiece(at: pos) {
                        if targetPiece.color != piece.color {
                            moves.append(pos)
                        }
                    } else {
                        moves.append(pos)
                    }
                }
            }
        }
        
        return moves
    }
    
    func isPositionValid(_ position: Position) -> Bool {
        position.x >= 0 && position.x < 8 && position.y >= 0 && position.y < 8
    }
    
    func checkGameStatus() {
        // TODO: Implémenter la logique pour vérifier l'échec, l'échec et mat, et le pat
        gameStatus = .inProgress
    }
}

struct ChessView: View {
    @StateObject private var game = ChessGame()
    @State private var boardSize: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fond de l'échiquier
                chessBoard(size: min(geometry.size.width, geometry.size.height))
                    .onAppear {
                        boardSize = min(geometry.size.width, geometry.size.height)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(0)
                
                // Surbrillance des cases possibles
                ForEach(game.possibleMoves, id: \.self) { position in
                    Rectangle()
                        .fill(Color.yellow.opacity(0.4))
                        .frame(width: boardSize / 8, height: boardSize / 8)
                        .position(
                            x: CGFloat(position.x) * boardSize / 8 + boardSize / 16,
                            y: CGFloat(position.y) * boardSize / 8 + boardSize / 16
                        )
                }
                
                // Pièces d'échecs
                ForEach(game.pieces) { piece in
                    ChessPieceView(piece: piece, size: boardSize / 8)
                        .position(
                            x: CGFloat(piece.position.x) * boardSize / 8 + boardSize / 16,
                            y: CGFloat(piece.position.y) * boardSize / 8 + boardSize / 16
                        )
                        .onTapGesture {
                            if game.selectedPiece?.id == piece.id {
                                // Désélectionner la pièce
                                game.selectedPiece = nil
                                game.possibleMoves = []
                            } else {
                                game.selectPiece(piece)
                            }
                        }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        guard game.selectedPiece != nil else { return }
                        
                        let boardPosition = getBoardPosition(from: value.location, boardSize: boardSize)
                        if game.possibleMoves.contains(boardPosition) {
                            game.movePiece(to: boardPosition)
                        }
                    }
            )
        }
        .background(Color(UIColor.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }
    
    // Fonction pour dessiner l'échiquier
    func chessBoard(size: CGFloat) -> some View {
        ZStack {
            // Image de l'échiquier en arrière-plan
            Image("ChessBoard")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
            
            // Grille invisible pour la logique de jeu
            VStack(spacing: 0) {
                ForEach(0..<8) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<8) { col in
                            Rectangle()
                                .fill(Color.clear) // Cases invisibles
                                .frame(width: size / 8, height: size / 8)
                                .onTapGesture {
                                    let position = Position(x: col, y: row)
                                    if game.possibleMoves.contains(position) {
                                        game.movePiece(to: position)
                                    }
                                }
                        }
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .aspectRatio(1, contentMode: .fit)
    }
    
    // Calculer la position sur l'échiquier à partir d'un point
    func getBoardPosition(from point: CGPoint, boardSize: CGFloat) -> Position {
        let squareSize = boardSize / 8
        let x = Int(point.x / squareSize)
        let y = Int(point.y / squareSize)
        return Position(x: x, y: y)
    }
}

// Vue pour dessiner une pièce d'échecs
struct ChessPieceView: View {
    let piece: ChessPiece
    let size: CGFloat
    
    var body: some View {
        // Symbole de la pièce sans cercle de fond
        Text(piece.type.symbol)
            .font(.system(size: size * 0.9))
            .fontWeight(.medium)
            .foregroundColor(piece.color == .white ? .white : .black)
            .frame(width: size, height: size)
    }
}

#Preview {
    ChessView()
}
