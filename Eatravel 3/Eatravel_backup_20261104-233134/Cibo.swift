import Foundation

// MARK: - Record Airtable

struct Cibo: Codable, Identifiable, Hashable {
    let id: String
    let createdTime: String?
    var fields: CiboCampi

    /// URL della foto (miniatura grande se disponibile).
    /// Nota: Airtable fa scadere questi URL dopo circa 2 ore, per questo l'app ricarica i dati.
    var fotoURL: URL? {
        guard let foto = fields.foto?.first else { return nil }
        return URL(string: foto.thumbnails?.large?.url ?? foto.url)
    }

    var fotoPiccolaURL: URL? {
        guard let foto = fields.foto?.first else { return nil }
        return URL(string: foto.thumbnails?.small?.url ?? foto.url)
    }
}

// MARK: - Campi della tabella "Cibi"
// I valori nutrizionali sono riferiti a 100 g.

struct CiboCampi: Codable, Hashable {
    var nome: String?
    var foto: [Allegato]?
    var categoria: String?
    var descrizione: String?
    var ingredienti: String?          // un ingrediente per riga
    var allergeni: [String]?
    var porzioneGrammi: Double?
    var calorie: Double?
    var proteine: Double?
    var carboidrati: Double?
    var zuccheri: Double?
    var grassi: Double?
    var grassiSaturi: Double?
    var fibre: Double?
    var sale: Double?

    enum CodingKeys: String, CodingKey {
        case nome = "Nome"
        case foto = "Foto"
        case categoria = "Categoria"
        case descrizione = "Descrizione"
        case ingredienti = "Ingredienti"
        case allergeni = "Allergeni"
        case porzioneGrammi = "Porzione (g)"
        case calorie = "Calorie (kcal)"
        case proteine = "Proteine (g)"
        case carboidrati = "Carboidrati (g)"
        case zuccheri = "Zuccheri (g)"
        case grassi = "Grassi (g)"
        case grassiSaturi = "Grassi saturi (g)"
        case fibre = "Fibre (g)"
        case sale = "Sale (g)"
    }

    var listaIngredienti: [String] {
        (ingredienti ?? "")
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    static let categorie = ["Primo", "Secondo", "Contorno", "Piatto unico", "Colazione",
                            "Dolce", "Frutta", "Snack", "Bevanda", "Altro"]

    static let tuttiAllergeni = ["Glutine", "Crostacei", "Uova", "Pesce", "Arachidi", "Soia",
                                 "Latte", "Frutta a guscio", "Sedano", "Senape", "Sesamo",
                                 "Solfiti", "Lupini", "Molluschi"]
}

// MARK: - Allegati (foto)

struct Allegato: Codable, Hashable {
    let id: String
    let url: String
    let filename: String?
    let size: Int?
    let type: String?
    let width: Int?
    let height: Int?
    let thumbnails: Miniature?
}

struct Miniature: Codable, Hashable {
    let small: Miniatura?
    let large: Miniatura?
    let full: Miniatura?
}

struct Miniatura: Codable, Hashable {
    let url: String
    let width: Int?
    let height: Int?
}

// MARK: - Strutture di richiesta/risposta API

struct RispostaLista: Decodable {
    let records: [Cibo]
    let offset: String?
}

struct RichiestaScrittura: Encodable {
    let fields: CiboCampi
    let typecast: Bool
}

struct RichiestaUpload: Encodable {
    let contentType: String
    let file: String      // base64
    let filename: String
}

struct RispostaEliminazione: Decodable {
    let id: String
    let deleted: Bool
}
