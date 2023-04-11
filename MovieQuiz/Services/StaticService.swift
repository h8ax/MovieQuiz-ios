import Foundation

protocol StatisticService {
    var gamesCount: Int { get }
    var gameRecord: GameRecord? { get }
    var totalAccuracy: Double { get }
    func store(correct: Int, total: Int)
}

class StatisticServiceImplementation: StatisticService {
    private let userDefaults: UserDefaults
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private var storedRecords: [GameRecord] {
        get {
            guard let data = userDefaults.object(forKey: "game_records") as? Data,
                  let records = try? decoder.decode([GameRecord].self, from: data) else {
                return []
            }
            return records
        }
        set {
            guard let data = try? encoder.encode(newValue) else { return }
            userDefaults.set(data, forKey: "game_records")
        }
    }
    
    var gamesCount: Int {
        return storedRecords.count
    }
    
    var gameRecord: GameRecord? {
        return storedRecords.max(by: { $0.correct < $1.correct })
    }
    
    var totalAccuracy: Double {
        let totalPlayed = Double(storedRecords.reduce(0, { $0 + $1.total }))
        let totalCorrect = Double(storedRecords.reduce(0, { $0 + $1.correct }))
        guard totalPlayed > 0 else {
            return 0.0
        }
        return totalCorrect / totalPlayed * 100
    }
    
    init(userDefaults: UserDefaults, decoder: JSONDecoder, encoder: JSONEncoder) {
        self.userDefaults = userDefaults
        self.decoder = decoder
        self.encoder = encoder
    }
    
    func store(correct: Int, total: Int) {
        let record = GameRecord(correct: correct, total: total, date: Date())
        var records = storedRecords
        records.append(record)
        storedRecords = records
    }
}
