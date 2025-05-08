import SwiftUI
import UIKit

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
            pieces.append(ChessPiece(type: .pawn, color: .black, position: Position(x: i, y: 1)))
            pieces.append(ChessPiece(type: .pawn, color: .white, position: Position(x: i, y: 6)))
        }
        
        // Ajouter les tours
        pieces.append(ChessPiece(type: .rook, color: .black, position: Position(x: 0, y: 0)))
        pieces.append(ChessPiece(type: .rook, color: .black, position: Position(x: 7, y: 0)))
        pieces.append(ChessPiece(type: .rook, color: .white, position: Position(x: 0, y: 7)))
        pieces.append(ChessPiece(type: .rook, color: .white, position: Position(x: 7, y: 7)))
        
        // Ajouter les cavaliers
        pieces.append(ChessPiece(type: .knight, color: .black, position: Position(x: 1, y: 0)))
        pieces.append(ChessPiece(type: .knight, color: .black, position: Position(x: 6, y: 0)))
        pieces.append(ChessPiece(type: .knight, color: .white, position: Position(x: 1, y: 7)))
        pieces.append(ChessPiece(type: .knight, color: .white, position: Position(x: 6, y: 7)))
        
        // Ajouter les fous
        pieces.append(ChessPiece(type: .bishop, color: .black, position: Position(x: 2, y: 0)))
        pieces.append(ChessPiece(type: .bishop, color: .black, position: Position(x: 5, y: 0)))
        pieces.append(ChessPiece(type: .bishop, color: .white, position: Position(x: 2, y: 7)))
        pieces.append(ChessPiece(type: .bishop, color: .white, position: Position(x: 5, y: 7)))
        
        // Ajouter les reines
        pieces.append(ChessPiece(type: .queen, color: .black, position: Position(x: 3, y: 0)))
        pieces.append(ChessPiece(type: .queen, color: .white, position: Position(x: 3, y: 7)))
        
        // Ajouter les rois
        pieces.append(ChessPiece(type: .king, color: .black, position: Position(x: 4, y: 0)))
        pieces.append(ChessPiece(type: .king, color: .white, position: Position(x: 4, y: 7)))
    }
    
    func getPiece(at position: Position) -> ChessPiece? {
        pieces.first { $0.position == position }
    }
    
    func selectPiece(_ piece: ChessPiece) {
        if piece.color == currentPlayer {
            print("📝 Sélection de pièce: \(piece.type) (\(piece.color)) à la position (\(piece.position.x), \(piece.position.y))")
            selectedPiece = piece
            possibleMoves = calculatePossibleMoves(for: piece)
            print("🔄 Nombre de mouvements possibles: \(possibleMoves.count)")
            
            // Afficher les mouvements possibles
            if !possibleMoves.isEmpty {
                print("📊 Mouvements possibles: \(possibleMoves.map { "(\($0.x), \($0.y))" }.joined(separator: ", "))")
            } else {
                print("⚠️ Aucun mouvement possible pour cette pièce")
            }
        } else {
            print("❌ Impossible de sélectionner une pièce de l'adversaire")
        }
    }
    
    func movePiece(to position: Position) {
        guard let piece = selectedPiece, possibleMoves.contains(position) else { 
            print("⚠️ Mouvement impossible: pièce non sélectionnée ou mouvement non valide")
            return 
        }
        
        print("🎮 Déplacement de \(piece.type) (\(piece.color)) de (\(piece.position.x), \(piece.position.y)) vers (\(position.x), \(position.y))")
        
        // Vérifier si une pièce adverse se trouve à la position cible
        if let capturedPiece = getPiece(at: position) {
            if capturedPiece.color != piece.color {
                print("⚔️ Capture de \(capturedPiece.type) (\(capturedPiece.color)) à la position (\(position.x), \(position.y))")
            capturedPieces.append(capturedPiece)
            pieces.removeAll { $0.id == capturedPiece.id }
                print("📊 Pièces restantes: \(pieces.count), Pièces capturées: \(capturedPieces.count)")
            } else {
                print("❌ Erreur: Tentative de capture d'une pièce alliée")
                return
            }
        } else {
            print("👉 Déplacement vers une case vide")
        }
        
        // Mettre à jour la position de la pièce
        if let index = pieces.firstIndex(where: { $0.id == piece.id }) {
            pieces[index].position = position
            pieces[index].hasMoved = true
            print("✅ Position mise à jour pour \(piece.type)")
        } else {
            print("❌ Pièce non trouvée dans la liste")
        }
        
        // Changer de joueur
        currentPlayer = currentPlayer == .white ? .black : .white
        print("👥 Tour du joueur: \(currentPlayer)")
        
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
                    print("🎯 Le pion en (\(piece.position.x), \(piece.position.y)) peut capturer en (\(pos.x), \(pos.y))")
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
                            print("🎯 La tour en (\(piece.position.x), \(piece.position.y)) peut capturer en (\(pos.x), \(pos.y))")
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
                            print("🎯 Le cavalier en (\(piece.position.x), \(piece.position.y)) peut capturer en (\(pos.x), \(pos.y))")
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
                            print("🎯 Le fou en (\(piece.position.x), \(piece.position.y)) peut capturer en (\(pos.x), \(pos.y))")
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
                            print("🎯 La dame en (\(piece.position.x), \(piece.position.y)) peut capturer en (\(pos.x), \(pos.y))")
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
                            print("🎯 Le roi en (\(piece.position.x), \(piece.position.y)) peut capturer en (\(pos.x), \(pos.y))")
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
            VStack {
                // Ajouter un Spacer avant l'échiquier pour le centrer verticalement
                Spacer().frame(height: geometry.size.height * 0.15)
                
                // Échiquier et pièces en un seul bloc
            ZStack {
                    // Base de l'échiquier
                    chessBoard(size: min(geometry.size.width, geometry.size.height * 0.7))
                    .onAppear {
                            boardSize = min(geometry.size.width, geometry.size.height * 0.7)
                    }
                
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
                        ChessPieceView(piece: piece, size: boardSize / 8, game: game)
                        .position(
                            x: CGFloat(piece.position.x) * boardSize / 8 + boardSize / 16,
                            y: CGFloat(piece.position.y) * boardSize / 8 + boardSize / 16
                        )
                    }
                }
                .frame(width: boardSize, height: boardSize)
                .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        guard game.selectedPiece != nil else { return }
                        
                            // Convertir les coordonnées du tap en position sur l'échiquier
                            let squareSize = boardSize / 8
                            let boardX = Int(value.location.x / squareSize)
                            let boardY = Int(value.location.y / squareSize)
                            
                            // S'assurer que les coordonnées sont dans les limites du plateau
                            guard boardX >= 0 && boardX < 8 && boardY >= 0 && boardY < 8 else { return }
                            
                            let position = Position(x: boardX, y: boardY)
                            print("👆 Tap détecté sur ZStack: (\(boardX), \(boardY))")
                            
                            // Vérifier si c'est un mouvement valide ou une capture
                            if game.possibleMoves.contains(position) {
                                print("✅ Mouvement valide via le geste global!")
                                
                                // Vérifier si c'est une capture
                                if let capturedPiece = game.getPiece(at: position) {
                                    print("⚔️ Capture de \(capturedPiece.type) (\(capturedPiece.color)) via geste global")
                                }
                                
                                game.movePiece(to: position)
                            } 
                            // Vérifier si l'utilisateur a tapé sur une de ses pièces (changement de sélection)
                            else if let newPiece = game.getPiece(at: position), newPiece.color == game.currentPlayer {
                                print("🔄 Changement de sélection via geste global")
                                game.selectedPiece = nil
                                game.possibleMoves = []
                                game.selectPiece(newPiece)
                            }
                            else {
                                print("❌ Position non valide via le geste global")
                            }
                        }
                )
                
                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(Color(UIColor.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }
    
    // Fonction pour dessiner l'échiquier
    func chessBoard(size: CGFloat) -> some View {
            VStack(spacing: 0) {
                ForEach(0..<8) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<8) { col in
                        let isRedCell = (row + col) % 2 == 1
                        let position = Position(x: col, y: row)
                        
                            Rectangle()
                            .fill(isRedCell ? Color(red: 0.8, green: 0.12, blue: 0.15) : Color(white: 0.12))
                                .frame(width: size / 8, height: size / 8)
                            .contentShape(Rectangle())
                                .onTapGesture {
                                print("🔍 Tap sur case individuelle: (\(col), \(row)) [position exacte]")
                                
                                // Vérifier si une pièce est sélectionnée
                                if let selectedPiece = game.selectedPiece {
                                    print("Pièce sélectionnée: \(selectedPiece.type) à (\(selectedPiece.position.x), \(selectedPiece.position.y))")
                                    print("Mouvements possibles: \(game.possibleMoves.map { "(\($0.x), \($0.y))" }.joined(separator: ", "))")
                                    
                                    // Vérifier si le mouvement est valide
                                    if game.possibleMoves.contains(position) {
                                        print("✓ Mouvement valide via case individuelle: (\(position.x), \(position.y))")
                                        game.movePiece(to: position)
                                    } else {
                                        print("✗ Mouvement non autorisé via case individuelle: (\(position.x), \(position.y))")
                                        
                                        // Essayer de sélectionner une pièce au lieu de déplacer
                                        if let piece = game.getPiece(at: position) {
                                            if piece.color == game.currentPlayer {
                                                print("Nouvelle sélection via case individuelle: \(piece.type)")
                                                game.selectedPiece = nil  // Désélectionner d'abord
                                                game.possibleMoves = []
                                                game.selectPiece(piece)   // Puis sélectionner nouvelle pièce
                                            } else {
                                                // Vérifier si la pièce adverse peut être capturée par la pièce sélectionnée
                                                if game.possibleMoves.contains(position) {
                                                    print("⚔️ Capture d'une pièce adverse")
                                                    game.movePiece(to: position)
                                                } else {
                                                    print("❌ Cette pièce adverse ne peut pas être capturée par la pièce sélectionnée")
                                                }
                                            }
                                        } else {
                                            print("Aucune pièce à sélectionner sur la case (\(col), \(row))")
                                        }
                                    }
                                } else {
                                    // Aucune pièce n'est sélectionnée, essayer d'en sélectionner une
                                    if let piece = game.getPiece(at: position), piece.color == game.currentPlayer {
                                        print("Sélection de pièce via case individuelle: \(piece.type)")
                                        game.selectPiece(piece)
                                    } else {
                                        print("Pas de pièce à sélectionner ou mauvaise couleur sur case (\(col), \(row))")
                                    }
                                }
                            }
                            .overlay(
                                // Ajouter un indicateur pour les mouvements possibles
                                game.possibleMoves.contains(position) ?
                                    Circle()
                                        .fill(Color.yellow.opacity(0.6))
                                        .frame(width: size / 16, height: size / 16)
                                        .padding(5) : nil
                            )
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// Vue pour dessiner une pièce d'échecs
struct ChessPieceView: View {
    let piece: ChessPiece
    let size: CGFloat
    @State private var dragOffset: CGSize = .zero
    @ObservedObject var game: ChessGame
    
    var body: some View {
        // Utiliser les images des pièces au lieu des symboles Unicode
        Image(uiImage: loadChessPieceImage(for: piece))
            .resizable()
            .scaledToFit()
            .frame(width: size * 0.9, height: size * 0.9)
            .offset(dragOffset)
            .onTapGesture {
                print("Tap sur pièce: \(piece.type) à (\(piece.position.x), \(piece.position.y))")
                
                // Si une pièce est déjà sélectionnée, vérifier si c'est une capture
                if let selectedPiece = game.selectedPiece, selectedPiece.id != piece.id {
                    // Vérifier si cette pièce peut être capturée par la pièce sélectionnée
                    if piece.color != game.currentPlayer && game.possibleMoves.contains(piece.position) {
                        print("⚔️ Capture via tap direct sur la pièce: \(piece.type) (\(piece.color))")
                        game.movePiece(to: piece.position)
                        return
                    }
                }
                
                // Si c'est la même pièce ou si aucune pièce n'est sélectionnée
                if game.selectedPiece?.id == piece.id {
                    game.selectedPiece = nil
                    game.possibleMoves = []
                } else if piece.color == game.currentPlayer {
                    game.selectPiece(piece)
                } else {
                    print("❌ Impossible de sélectionner une pièce de l'adversaire")
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Permettre le glissement uniquement pour les pièces du joueur actuel
                        if piece.color == game.currentPlayer {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        // Réinitialiser l'offset
                        dragOffset = .zero
                        
                        // Permettre le glissement uniquement pour les pièces du joueur actuel
                        if piece.color != game.currentPlayer {
                            return
                        }
                        
                        // Sélectionner la pièce si ce n'est pas déjà fait
                        if game.selectedPiece?.id != piece.id {
                            game.selectPiece(piece)
                        }
                        
                        guard !game.possibleMoves.isEmpty else { return }
                        
                        // Calculer la case cible du drop
                        let dragEndLocation = value.location
                        let squareSize = size // Taille d'une case
                        
                        // Calculer la position relative par rapport à la pièce
                        let initialPiecePosition = CGPoint(
                            x: CGFloat(piece.position.x) * squareSize,
                            y: CGFloat(piece.position.y) * squareSize
                        )
                        
                        // Position finale après le drag (relativement à la case d'origine)
                        let finalDragPosition = CGPoint(
                            x: initialPiecePosition.x + dragEndLocation.x,
                            y: initialPiecePosition.y + dragEndLocation.y
                        )
                        
                        // Convertir en position de l'échiquier
                        let targetCol = Int(finalDragPosition.x / squareSize)
                        let targetRow = Int(finalDragPosition.y / squareSize)
                        
                        // Vérifier que les coordonnées sont valides
                        guard targetCol >= 0 && targetCol < 8 && targetRow >= 0 && targetRow < 8 else { return }
                        
                        let targetPosition = Position(x: targetCol, y: targetRow)
                        print("🎯 Drag and drop: de (\(piece.position.x), \(piece.position.y)) vers (\(targetCol), \(targetRow))")
                        
                        // Vérifier si le mouvement est valide
                        if game.possibleMoves.contains(targetPosition) {
                            // Vérifier si c'est une capture
                            if let capturedPiece = game.getPiece(at: targetPosition) {
                                print("⚔️ Capture via drag-and-drop: \(capturedPiece.type) (\(capturedPiece.color))")
                            }
                            
                            print("✅ Mouvement valide via drag and drop!")
                            game.movePiece(to: targetPosition)
                        } else {
                            print("❌ Position non valide via drag and drop")
                        }
                    }
            )
    }
    
    // Fonction pour charger l'image de la pièce d'échecs
    private func loadChessPieceImage(for piece: ChessPiece) -> UIImage {
        let colorPrefix = piece.color == .white ? "white" : "black"
        var typeName = ""
        
        switch piece.type {
        case .pawn:
            typeName = "pawn"
        case .rook:
            typeName = "rook"
        case .knight:
            typeName = "knight"
        case .bishop:
            typeName = "bishop"
        case .queen:
            typeName = "queen"
        case .king:
            typeName = "king"
        }
        
        // Note: "white_cavalier.png" est utilisé pour le knight blanc selon le contenu du dossier
        if piece.color == .white && piece.type == .knight {
            typeName = "cavalier"
        }
        
        let imageName = "\(colorPrefix)_\(typeName)"
        
        // Option 1: Essayer de charger l'image depuis Assets.xcassets
        if let image = UIImage(named: imageName) {
            print("Image chargée depuis Assets.xcassets: \(imageName)")
            return image
        }
        
        // Option 2: Essayer de charger l'image depuis le répertoire "Pieces d'echec " (avec espace)
        if let path = Bundle.main.path(forResource: imageName, ofType: "png", inDirectory: "Pieces d'echec "),
           let image = UIImage(contentsOfFile: path) {
            print("Image chargée depuis Pieces d'echec (avec espace): \(imageName)")
            return image
        }
        
        // Option 3: Essayer de charger l'image depuis le répertoire "Pieces d'echec" (sans espace)
        if let path = Bundle.main.path(forResource: imageName, ofType: "png", inDirectory: "Pieces d'echec"),
           let image = UIImage(contentsOfFile: path) {
            print("Image chargée depuis Pieces d'echec (sans espace): \(imageName)")
            return image
        }
        
        // Option 4: Chemin d'accès direct au fichier
        let possiblePaths = [
            Bundle.main.bundleURL.appendingPathComponent("Pieces d'echec ").appendingPathComponent("\(imageName).png"),
            Bundle.main.bundleURL.appendingPathComponent("Pieces d'echec").appendingPathComponent("\(imageName).png")
        ]
        
        for imageURL in possiblePaths {
            if let image = UIImage(contentsOfFile: imageURL.path) {
                print("Image chargée via chemin direct: \(imageURL.path)")
                return image
            }
        }
        
        // Si le white_king n'a pas d'extension dans le nom de fichier (selon le nom observé dans le dossier)
        if piece.color == .white && piece.type == .king {
            if let path = Bundle.main.path(forResource: "white_king", ofType: "", inDirectory: "Pieces d'echec "),
               let image = UIImage(contentsOfFile: path) {
                print("Image du roi blanc chargée sans extension")
                return image
            }
        }
        
        // Dernier recours : image de remplacement
        print("❌ Échec de chargement de l'image: \(imageName).png")
        print("Chemins essayés: \(possiblePaths.map { $0.path }.joined(separator: ", "))")
        
        // Par défaut, utiliser le symbole text comme avant
        let fallbackImage = UIImage(systemName: "questionmark.square") ?? UIImage()
        return fallbackImage
    }
}

#Preview {
    ChessView()
}
