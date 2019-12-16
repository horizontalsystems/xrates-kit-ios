import Foundation

class ThreadSafeDictionary<KeyType: Hashable, ValueType> {
    private var dictionary = [KeyType: ValueType]()
    private let queue = DispatchQueue(label: "io.horizontalsystems.xrates-kit-ios.thread_safe_dictionary", attributes: .concurrent)

    subscript(key: KeyType) -> ValueType? {
        set {
            queue.async(flags: .barrier) {
                self.dictionary[key] = newValue
            }
        }
        get {
            queue.sync {
                self.dictionary[key]
            }
        }
    }

    func removeAll() {
        queue.async(flags: .barrier) {
            self.dictionary.removeAll()
        }
    }

}

class ThreadSafeArray<T> {
    private var array = [T]()
    private let queue = DispatchQueue(label: "io.horizontalsystems.xrates-kit-ios.thread_safe_array", attributes: .concurrent)

    func append(_ newElement: T) {
        queue.async(flags: .barrier) {
            self.array.append(newElement)
        }
    }

}

extension ThreadSafeArray where T: Equatable {

    func contains(_ element: T) -> Bool {
        queue.sync {
            self.array.contains(element)
        }
    }

}
