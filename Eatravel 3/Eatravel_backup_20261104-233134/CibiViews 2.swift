import SwiftUI
import PhotosUI

// MARK: - Lista dei cibi (schermata principale di test)

struct CibiListView: View {
    @State private var cibi: [Cibo] = []
    @State private var caricamento = false
    @State private var errore: String?
    @State private var mostraAggiungi = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(cibi) { cibo in
                    NavigationLink(value: cibo) { RigaCibo(cibo: cibo) }
                }
                .onDelete(perform: elimina)
            }
            .overlay {
                if caricamento && cibi.isEmpty { ProgressView() }
                else if !caricamento && cibi.isEmpty { Text("Nessun cibo").foregroundStyle(.secondary) }
            }
            .navigationTitle("Cibi")
            .navigationDestination(for: Cibo.self) { CiboDetailView(cibo: $0) }
            .toolbar {
                Button { mostraAggiungi = true } label: { Image(systemName: "plus") }
            }
            .sheet(isPresented: $mostraAggiungi) {
                AggiungiCiboView { Task { await carica() } }
            }
            .refreshable { await carica() }
            .task { await carica() }
            .alert("Errore", isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(errore ?? "") }
        }
    }

    private func carica() async {
        caricamento = true
        defer { caricamento = false }
        do { cibi = try await AirtableService.shared.caricaCibi() }
        catch { errore = error.localizedDescription }
    }

    private func elimina(at indici: IndexSet) {
        let daEliminare = indici.map { cibi[$0] }
        cibi.remove(atOffsets: indici)
        Task {
            for cibo in daEliminare {
                do { try await AirtableService.shared.eliminaCibo(id: cibo.id) }
                catch { errore = error.localizedDescription }
            }
        }
    }
}

struct RigaCibo: View {
    let cibo: Cibo

    var body: some View {
        HStack(spacing: 12) {
            FotoCibo(url: cibo.fotoPiccolaURL)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(cibo.fields.nome ?? "Senza nome").font(.headline)
                HStack {
                    if let categoria = cibo.fields.categoria { Text(categoria) }
                    if let kcal = cibo.fields.calorie { Text("· \(formatta(kcal)) kcal/100 g") }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
    }
}

struct FotoCibo: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { fase in
            switch fase {
            case .success(let img): img.resizable().scaledToFill()
            default:
                ZStack {
                    Color.gray.opacity(0.15)
                    Image(systemName: "fork.knife").foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Dettaglio

struct CiboDetailView: View {
    let cibo: Cibo

    var body: some View {
        List {
            if cibo.fotoURL != nil {
                Section {
                    FotoCibo(url: cibo.fotoURL)
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .listRowInsets(EdgeInsets())
                }
            }
            Section("Informazioni") {
                if let c = cibo.fields.categoria { LabeledContent("Categoria", value: c) }
                if let p = cibo.fields.porzioneGrammi { LabeledContent("Porzione", value: "\(formatta(p)) g") }
                if let d = cibo.fields.descrizione, !d.isEmpty { Text(d) }
            }
            if !cibo.fields.listaIngredienti.isEmpty {
                Section("Ingredienti") {
                    ForEach(cibo.fields.listaIngredienti, id: \.self) { Text($0) }
                }
            }
            if let allergeni = cibo.fields.allergeni, !allergeni.isEmpty {
                Section("Allergeni") { Text(allergeni.joined(separator: ", ")) }
            }
            Section("Valori nutrizionali per 100 g") {
                riga("Energia", cibo.fields.calorie, "kcal")
                riga("Proteine", cibo.fields.proteine, "g")
                riga("Carboidrati", cibo.fields.carboidrati, "g")
                riga("  di cui zuccheri", cibo.fields.zuccheri, "g")
                riga("Grassi", cibo.fields.grassi, "g")
                riga("  di cui saturi", cibo.fields.grassiSaturi, "g")
                riga("Fibre", cibo.fields.fibre, "g")
                riga("Sale", cibo.fields.sale, "g")
            }
        }
        .navigationTitle(cibo.fields.nome ?? "Cibo")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func riga(_ nome: String, _ valore: Double?, _ unita: String) -> some View {
        LabeledContent(nome, value: valore.map { "\(formatta($0)) \(unita)" } ?? "—")
    }
}

// MARK: - Aggiungi cibo

struct AggiungiCiboView: View {
    var onSalvato: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var nome = ""
    @State private var categoria = "Altro"
    @State private var descrizione = ""
    @State private var ingredienti = ""
    @State private var allergeni: Set<String> = []
    @State private var porzione = ""
    @State private var calorie = ""
    @State private var proteine = ""
    @State private var carboidrati = ""
    @State private var zuccheri = ""
    @State private var grassi = ""
    @State private var saturi = ""
    @State private var fibre = ""
    @State private var sale = ""

    @State private var selezioneFoto: PhotosPickerItem?
    @State private var immagine: UIImage?
    @State private var salvataggio = false
    @State private var errore: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Foto") {
                    PhotosPicker(selection: $selezioneFoto, matching: .images) {
                        if let immagine {
                            Image(uiImage: immagine).resizable().scaledToFill()
                                .frame(height: 180).frame(maxWidth: .infinity).clipped()
                        } else {
                            Label("Scegli una foto", systemImage: "photo")
                        }
                    }
                }
                Section("Informazioni") {
                    TextField("Nome *", text: $nome)
                    Picker("Categoria", selection: $categoria) {
                        ForEach(CiboCampi.categorie, id: \.self) { Text($0) }
                    }
                    TextField("Descrizione", text: $descrizione, axis: .vertical)
                    campoNumero("Porzione (g)", $porzione)
                }
                Section {
                    TextField("Un ingrediente per riga", text: $ingredienti, axis: .vertical)
                        .lineLimit(3...10)
                } header: { Text("Ingredienti") }
                Section("Allergeni") {
                    ForEach(CiboCampi.tuttiAllergeni, id: \.self) { a in
                        Toggle(a, isOn: Binding(
                            get: { allergeni.contains(a) },
                            set: { if $0 { allergeni.insert(a) } else { allergeni.remove(a) } }))
                    }
                }
                Section("Valori nutrizionali per 100 g") {
                    campoNumero("Calorie (kcal)", $calorie)
                    campoNumero("Proteine (g)", $proteine)
                    campoNumero("Carboidrati (g)", $carboidrati)
                    campoNumero("di cui zuccheri (g)", $zuccheri)
                    campoNumero("Grassi (g)", $grassi)
                    campoNumero("di cui saturi (g)", $saturi)
                    campoNumero("Fibre (g)", $fibre)
                    campoNumero("Sale (g)", $sale)
                }
            }
            .navigationTitle("Nuovo cibo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if salvataggio { ProgressView() }
                    else {
                        Button("Salva") { Task { await salva() } }
                            .disabled(nome.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .task(id: selezioneFoto) {
                guard let selezioneFoto,
                      let dati = try? await selezioneFoto.loadTransferable(type: Data.self) else { return }
                immagine = UIImage(data: dati)
            }
            .alert("Errore", isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(errore ?? "") }
        }
    }

    private func campoNumero(_ titolo: String, _ testo: Binding<String>) -> some View {
        HStack {
            Text(titolo)
            Spacer()
            TextField("0", text: testo)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 100)
        }
    }

    private func salva() async {
        salvataggio = true
        defer { salvataggio = false }

        let campi = CiboCampi(
            nome: nome.trimmingCharacters(in: .whitespaces),
            categoria: categoria,
            descrizione: descrizione.isEmpty ? nil : descrizione,
            ingredienti: ingredienti.isEmpty ? nil : ingredienti,
            allergeni: allergeni.isEmpty ? nil : CiboCampi.tuttiAllergeni.filter { allergeni.contains($0) },
            porzioneGrammi: numero(porzione),
            calorie: numero(calorie),
            proteine: numero(proteine),
            carboidrati: numero(carboidrati),
            zuccheri: numero(zuccheri),
            grassi: numero(grassi),
            grassiSaturi: numero(saturi),
            fibre: numero(fibre),
            sale: numero(sale))

        do {
            _ = try await AirtableService.shared.creaCibo(campi, immagine: immagine)
            onSalvato()
            dismiss()
        } catch {
            errore = error.localizedDescription
        }
    }

    /// Accetta sia "2,5" che "2.5".
    private func numero(_ testo: String) -> Double? {
        Double(testo.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces))
    }
}

// MARK: - Formattazione numeri

func formatta(_ valore: Double) -> String {
    valore.formatted(.number.precision(.fractionLength(0...2)))
}

#Preview { CibiListView() }
