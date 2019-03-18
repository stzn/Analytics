import Foundation

public final class Library {
    private var library: [Book] = []
    
    public init() {}
    
    public func add(_ book: Book) -> Book {
        library.append(book)
        return book
    }
    
    public func delete(at index: Int) -> Book? {
        guard library.count - 1 >= index else {
            return nil
        }
        return library.remove(at: index)
    }
    
    public func read(at index: Int) -> Book? {
        guard library.count - 1 >= index else {
            return nil
        }
        return library[index]
    }
}
