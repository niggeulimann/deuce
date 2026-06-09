import Foundation

/// Transport object for sending a finished match from the Watch to the iPhone
/// via WatchConnectivity. Mirrors every field of `MatchRecord` and is Codable
/// so it can be JSON-encoded into a `transferUserInfo` payload.
struct MatchRecordDTO: Codable, Identifiable {
    var id: UUID
    var syncUpdatedAt: Date
    var isDeleted: Bool
    var date: Date
    var surface: String
    var noAd: Bool
    var gamesPerSet: Int
    var setsToWin: Int
    var isComplete: Bool

    var setsTop: Int
    var setsBottom: Int
    var setScoresTop: [Int]
    var setScoresBottom: [Int]
    var currentGamesTop: Int
    var currentGamesBottom: Int
    var currentPointsTop: Int
    var currentPointsBottom: Int
    var didWin: Bool

    var opponentName: String
    var notes: String

    var matchStartDate: Date
    var firstPointOffset: Double
    var pointOffsets: [Double]
    var gameOffsets: [Double]
    var setOffsets: [Double]

    init(id: UUID,
         syncUpdatedAt: Date = Date(),
         isDeleted: Bool = false,
         date: Date,
         surface: String,
         noAd: Bool,
         gamesPerSet: Int,
         setsToWin: Int,
         isComplete: Bool,
         setsTop: Int,
         setsBottom: Int,
         setScoresTop: [Int],
         setScoresBottom: [Int],
         currentGamesTop: Int,
         currentGamesBottom: Int,
         currentPointsTop: Int,
         currentPointsBottom: Int,
         didWin: Bool,
         opponentName: String,
         notes: String,
         matchStartDate: Date,
         firstPointOffset: Double,
         pointOffsets: [Double],
         gameOffsets: [Double],
         setOffsets: [Double]) {
        self.id = id
        self.syncUpdatedAt = syncUpdatedAt
        self.isDeleted = isDeleted
        self.date = date
        self.surface = surface
        self.noAd = noAd
        self.gamesPerSet = gamesPerSet
        self.setsToWin = setsToWin
        self.isComplete = isComplete
        self.setsTop = setsTop
        self.setsBottom = setsBottom
        self.setScoresTop = setScoresTop
        self.setScoresBottom = setScoresBottom
        self.currentGamesTop = currentGamesTop
        self.currentGamesBottom = currentGamesBottom
        self.currentPointsTop = currentPointsTop
        self.currentPointsBottom = currentPointsBottom
        self.didWin = didWin
        self.opponentName = opponentName
        self.notes = notes
        self.matchStartDate = matchStartDate
        self.firstPointOffset = firstPointOffset
        self.pointOffsets = pointOffsets
        self.gameOffsets = gameOffsets
        self.setOffsets = setOffsets
    }
}

extension MatchRecordDTO {
    /// Build a DTO from a persisted record (Watch side).
    init(_ r: MatchRecord) {
        self.init(
            id: r.id,
            syncUpdatedAt: r.syncUpdatedAt,
            isDeleted: r.isDeleted,
            date: r.date,
            surface: r.surface,
            noAd: r.noAd,
            gamesPerSet: r.gamesPerSet,
            setsToWin: r.setsToWin,
            isComplete: r.isComplete,
            setsTop: r.setsTop,
            setsBottom: r.setsBottom,
            setScoresTop: r.setScoresTop,
            setScoresBottom: r.setScoresBottom,
            currentGamesTop: r.currentGamesTop,
            currentGamesBottom: r.currentGamesBottom,
            currentPointsTop: r.currentPointsTop,
            currentPointsBottom: r.currentPointsBottom,
            didWin: r.didWin,
            opponentName: r.opponentName,
            notes: r.notes,
            matchStartDate: r.matchStartDate,
            firstPointOffset: r.firstPointOffset,
            pointOffsets: r.pointOffsets,
            gameOffsets: r.gameOffsets,
            setOffsets: r.setOffsets
        )
    }

    /// Materialise a fresh `MatchRecord` from this DTO (iPhone side).
    func makeRecord() -> MatchRecord {
        MatchRecord(
            id: id,
            syncUpdatedAt: syncUpdatedAt,
            isDeleted: isDeleted,
            date: date,
            surface: surface,
            noAd: noAd,
            gamesPerSet: gamesPerSet,
            setsToWin: setsToWin,
            isComplete: isComplete,
            setsTop: setsTop,
            setsBottom: setsBottom,
            setScoresTop: setScoresTop,
            setScoresBottom: setScoresBottom,
            currentGamesTop: currentGamesTop,
            currentGamesBottom: currentGamesBottom,
            currentPointsTop: currentPointsTop,
            currentPointsBottom: currentPointsBottom,
            didWin: didWin,
            opponentName: opponentName,
            notes: notes,
            matchStartDate: matchStartDate,
            firstPointOffset: firstPointOffset,
            pointOffsets: pointOffsets,
            gameOffsets: gameOffsets,
            setOffsets: setOffsets
        )
    }

    // MARK: - Wire encoding helpers

    /// Encode to JSON Data for a WCSession userInfo payload.
    func encoded() -> Data? { try? JSONEncoder.deuce.encode(self) }

    /// Decode from a WCSession userInfo payload.
    static func decode(from data: Data) -> MatchRecordDTO? {
        try? JSONDecoder.deuce.decode(MatchRecordDTO.self, from: data)
    }

    static func encode(_ records: [MatchRecordDTO]) -> Data? {
        try? JSONEncoder.deuce.encode(records)
    }

    static func decodeList(from data: Data) -> [MatchRecordDTO]? {
        try? JSONDecoder.deuce.decode([MatchRecordDTO].self, from: data)
    }
}

extension MatchRecordDTO {
    private enum CodingKeys: String, CodingKey {
        case id, syncUpdatedAt, isDeleted, date, surface, noAd, gamesPerSet, setsToWin, isComplete
        case setsTop, setsBottom, setScoresTop, setScoresBottom
        case currentGamesTop, currentGamesBottom, currentPointsTop, currentPointsBottom, didWin
        case opponentName, notes, matchStartDate, firstPointOffset, pointOffsets, gameOffsets, setOffsets
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        syncUpdatedAt = try c.decodeIfPresent(Date.self, forKey: .syncUpdatedAt) ?? date
        isDeleted = try c.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
        surface = try c.decode(String.self, forKey: .surface)
        noAd = try c.decode(Bool.self, forKey: .noAd)
        gamesPerSet = try c.decode(Int.self, forKey: .gamesPerSet)
        setsToWin = try c.decode(Int.self, forKey: .setsToWin)
        isComplete = try c.decode(Bool.self, forKey: .isComplete)
        setsTop = try c.decode(Int.self, forKey: .setsTop)
        setsBottom = try c.decode(Int.self, forKey: .setsBottom)
        setScoresTop = try c.decode([Int].self, forKey: .setScoresTop)
        setScoresBottom = try c.decode([Int].self, forKey: .setScoresBottom)
        currentGamesTop = try c.decode(Int.self, forKey: .currentGamesTop)
        currentGamesBottom = try c.decode(Int.self, forKey: .currentGamesBottom)
        currentPointsTop = try c.decode(Int.self, forKey: .currentPointsTop)
        currentPointsBottom = try c.decode(Int.self, forKey: .currentPointsBottom)
        didWin = try c.decode(Bool.self, forKey: .didWin)
        opponentName = try c.decodeIfPresent(String.self, forKey: .opponentName) ?? ""
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        matchStartDate = try c.decodeIfPresent(Date.self, forKey: .matchStartDate) ?? date
        firstPointOffset = try c.decodeIfPresent(Double.self, forKey: .firstPointOffset) ?? -1
        pointOffsets = try c.decodeIfPresent([Double].self, forKey: .pointOffsets) ?? []
        gameOffsets = try c.decodeIfPresent([Double].self, forKey: .gameOffsets) ?? []
        setOffsets = try c.decodeIfPresent([Double].self, forKey: .setOffsets) ?? []
    }
}

extension JSONEncoder {
    static var deuce: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(DateCoding.string(from: date))
        }
        return e
    }
}

extension JSONDecoder {
    static var deuce: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = DateCoding.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(value)")
        }
        return d
    }
}

private enum DateCoding {
    static func string(from date: Date) -> String {
        formatter(withFractions: true).string(from: date)
    }

    static func date(from value: String) -> Date? {
        formatter(withFractions: true).date(from: value) ?? formatter(withFractions: false).date(from: value)
    }

    private static func formatter(withFractions: Bool) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = withFractions ? [.withInternetDateTime, .withFractionalSeconds] : [.withInternetDateTime]
        return formatter
    }
}
