struct Array2D<Element>: Sequence, CustomStringConvertible {
    typealias Coord = (row: Int, col: Int)
    let quadDirectionUnitVec = [(0, 1), (-1, 0), (0, -1), (1, 0)]
    let octaDirectionUnitVec = [(0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1), (1, 0), (1, 1)]

    private(set) var originWidth: Int
    private(set) var originHeight: Int
    var width: Int {
        rotation.isMultiple(of: 2) ? originWidth : originHeight
    }
    var height: Int {
        rotation.isMultiple(of: 2) ? originHeight : originWidth
    }
    private(set) var elements: [Element]
    private(set) var rotation: Int = 0
    let outside: Element?
    init(height: Int, width: Int, elements: [Element], outside: Element? = nil) {
        precondition(elements.count == width * height)
        self.originWidth = width
        self.originHeight = height
        self.elements = elements
        self.outside = outside
    }
    init(height: Int, width: Int, element: Element, outside: Element? = nil) {
        self.init(height: height, width: width, elements: [Element](repeating: element, count: width * height), outside: outside)
    }
    var count: Int { elements.count }
    var originRowRange: Range<Int> { 0 ..< originHeight }
    var originColRange: Range<Int> { 0 ..< originWidth }
    private func boardContains(coord: Coord) -> Bool { originRowRange.contains(coord.row) && originColRange.contains(coord.col) }
    private func boardNotContains(coord: Coord) -> Bool { !boardContains(coord: coord) }
    private func indexOriginAt(r: Int, c: Int) -> Int? {
        guard originRowRange.contains(r) else { return nil }
        guard originColRange.contains(c) else { return nil }
        return r * originWidth + c
    }
    private func indexAt(r: Int, c: Int) -> Int? {
        switch rotation {
        case 0:
            return indexOriginAt(r: r, c: c)
        case 1:
            guard originColRange.contains(r) else { return nil }
            guard originRowRange.contains(c) else { return nil }
            return indexOriginAt(r: originHeight - 1 - c, c: r)
        case 2:
            return indexOriginAt(r: originHeight - 1 - r, c: originWidth - 1 - c)
        case 3:
            guard originColRange.contains(r) else { return nil }
            guard originRowRange.contains(c) else { return nil }
            return indexOriginAt(r: c, c: originWidth - 1 - r)
        default:
            fatalError("illegal rotation value: \(rotation)")
        }
    }
    subscript(r: Int, c: Int) -> Element {
        get {
            guard let i = indexAt(r: r, c: c) else {
                guard let os = outside else {
                    fatalError("(r, c)=(\(r),\(c)) is outside and the outside value of Array2D is not defined.")
                }
                return os
            }
            return elements[i]
        }
        set {
            guard let i = indexAt(r: r, c: c) else {
                precondition(outside != nil)
                return
            }
            elements[i] = newValue
        }
    }
    subscript(position: Coord) -> Element {
        get { self[position.0, position.1] }
        set { self[position.0, position.1] = newValue }
    }
    func makeIterator() -> IndexingIterator<[Element]> {
        elements.makeIterator()
    }
    func map<T>(_ transform: (Element) throws -> T) rethrows -> Array2D<T> {
        try Array2D<T>(height: originHeight, width: originWidth, elements: elements.map(transform))
    }
    func neighbours(around now: Coord, ignoreOutside: Bool = true) -> [Coord] {
        var res = [Coord]()
        for i in 0..<4 {
            let nr = now.row + quadDirectionUnitVec[i].0
            let nc = now.col + quadDirectionUnitVec[i].1
            if ignoreOutside && boardNotContains(coord: (row: nr, col: nc)) {
                continue
            }
            res.append((nr, nc))
        }
        return res
    }
    func surroundings(around now: Coord, ignoreOutside: Bool = true) -> [Coord] {
        var res = [Coord]()
        for i in 0..<8 {
            let nr = now.row + octaDirectionUnitVec[i].0
            let nc = now.col + octaDirectionUnitVec[i].1
            if ignoreOutside {
                if indexAt(r: nr, c: nc) == nil {
                    continue
                }
            }
            res.append((nr, nc))
        }
        return res
    }
    func locationList(condition: (Element) -> Bool) -> [Coord] {
        var res = [Coord]()
        for (i, e) in elements.enumerated() {
            guard condition(e) else { continue }
            res.append((row: i / originWidth, i % originWidth))
        }
        return res
    }
    mutating func rotate(count: Int = 1) {
        rotation += count
        rotation = rotation % 4
    }
    mutating func resetAndRotate(count: Int) {
        rotation = count % 4
    }
    var description: String {
        var result: String = ""
        for r in originRowRange {
            for c in originColRange {
                if c > 0 {
                    result.append(" ")
                }
                result.append("\(self[r, c])")
            }
            result.append("\n")
        }
        return result
    }
}
extension Array2D where Element: Equatable {
    func trimmed(removing e: Element) -> Array2D<Element> {
        let tb = trimmedBoard(removing: e)
        return Array2D<Element>(height: tb.height, width: tb.width, elements: tb.elements)
    }
    mutating func trim(removing e: Element) {
        let tb = trimmedBoard(removing: e)
        self.elements = tb.elements
        self.originWidth = tb.width
        self.originHeight = tb.height
    }
    private func trimmedBoard(removing e: Element) -> (elements: [Element], width: Int, height: Int) {
        var left = width - 1, right = 0, top = height - 1, bottom = 0
        // Swift.min と Collection.min が衝突してて Linux 環境上での世話がめんどいので車輪を再発明
        func vmin(_ a: Int, _ b: Int) -> Int { a < b ? a : b }
        func vmax(_ a: Int, _ b: Int) -> Int { a > b ? a : b }
        for r in 0..<height {
            for c in 0..<width {
                if self[r, c] != e {
                    left = vmin(left, c)
                    right = vmax(right, c)
                    top = vmin(top, r)
                    bottom = vmax(bottom, r)
                }
            }
        }
        var newElements = [Element]()
        for r in top...bottom {
            for c in left...right {
                newElements.append(self[r, c])
            }
        }
        return (newElements, right - left + 1, bottom - top + 1)
    }
}
extension Array2D where Element: CustomStringConvertible {
    var description: String {
        var result: String = ""
        for r in originRowRange {
            for c in originColRange {
                if c > 0 {
                    result.append(" ")
                }
                result.append(self[r, c].description)
            }
            result.append("\n")
        }
        return result
    }
}
extension Array2D where Element == Character {
    init(height: Int, width: Int, stringArray: [String], outside: Element? = nil) {
        let array = stringArray.map { s in Array(s) }.flatMap { $0 }
        self.init(height: height, width: width, elements: array, outside: outside)
    }
    func seek(word: String) -> [Coord]? {
        let wcs = Array(word)
        for row in 0..<originHeight {
            for col in 0..<originWidth {
                for (ir, ic) in octaDirectionUnitVec {
                    var buf = ""
                    var loc = [Coord]()
                    for scale in 0..<wcs.count {
                        let destination = (row + scale * ir, col + scale * ic)
                        guard boardContains(coord: destination) else { break }
                        buf.append(self[destination])
                        loc.append(destination)
                    }
                    if buf == word {
                        return loc
                    }
                }
            }
        }
        return nil
    }
}