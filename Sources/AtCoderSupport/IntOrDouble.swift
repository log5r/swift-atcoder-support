struct Iod: CustomStringConvertible, Hashable, Equatable, Comparable, AdditiveArithmetic, ExpressibleByIntegerLiteral {
    typealias IntegerLiteralType = Int
    let intValue: Int
    let doubleValue: Double
    let isInt: Bool
    var description: String {
        isInt ? "\(intValue)(f: \(doubleValue))" : "\(doubleValue)(i: \(intValue))"
    }
    init(_ i: Int) {
        intValue = i
        doubleValue = Double(i)
        isInt = true
    }
    init(_ d: Double) {
        intValue = Int(d)
        doubleValue = d
        isInt = false
    }
    init(integerLiteral value: IntegerLiteralType) {
        intValue = Int(value)
        doubleValue = Double(value)
        isInt = type(of: value) == Int.self
    }

    static var zero = Iod(0)
    static func + (lhs: Self, rhs: Self) -> Self { proc(lhs, rhs, +, +) }
    static func - (lhs: Self, rhs: Self) -> Self { proc(lhs, rhs, -, -)}
    static func * (lhs: Self, rhs: Self) -> Self { proc(lhs, rhs, *, *) }
    static func / (lhs: Self, rhs: Self) -> Self { proc(lhs, rhs, /, /) }
    static func += (lhs: inout Self, rhs: Self) { lhs = lhs + rhs }
    static func -= (lhs: inout Self, rhs: Self) { lhs = lhs - rhs }
    static func *= (lhs: inout Self, rhs: Self) { lhs = lhs * rhs }
    static func /= (lhs: inout Self, rhs: Self) { lhs = lhs / rhs }

    static func < (lhs: Self, rhs: Self) -> Bool {
        preconditionCheck(note: "compare", lhs: lhs, rhs: rhs)
        return lhs.isInt ? lhs.intValue < rhs.intValue : lhs.doubleValue < rhs.doubleValue
    }
    static func == (lhs: Self, rhs: Self) -> Bool {
        preconditionCheck(note: "equal", lhs: lhs, rhs: rhs)
        return lhs.isInt ? lhs.intValue == rhs.intValue : lhs.doubleValue == rhs.doubleValue
    }
    private static func proc(_ lhs:Self, _ rhs:Self, _ f:(Int, Int) -> Int, _ g:(Double, Double) -> Double) -> Self {
        preconditionCheck(lhs: lhs, rhs: rhs)
        let i = f(lhs.intValue, rhs.intValue)
        let d = g(lhs.doubleValue, rhs.doubleValue)
        return lhs.isInt ? Iod(i) : Iod(d)
    }
    private static func preconditionCheck(note: String = "", lhs: Self, rhs: Self) {
        if lhs.isInt != rhs.isInt {
            let u = lhs.isInt ? "Int" : "Double"
            let v = rhs.isInt ? "Int" : "Double"
            fatalError("Cannot perform \(note)! lhs is \(u), rhs is \(v)")
        }
    }
}
