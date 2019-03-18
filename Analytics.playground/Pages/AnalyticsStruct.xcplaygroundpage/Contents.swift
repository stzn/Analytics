import UIKit

// structで定義

struct AnalyticsEvent {
    let name: String
    let metadata: [String: Any]
    
    private init(name: String, metadata: [String: Any] = [:]) {
        self.name = name
        self.metadata = metadata
    }
}

final class AnalyticsManager {
    private let engine: AnalyticsEngine
    init(engine: AnalyticsEngine) {
        self.engine = engine
    }
    
    func log(_ event: AnalyticsEvent) {
        engine.send(name: event.name, metadata: event.metadata)
    }
}

protocol AnalyticsEngine: AnyObject {
    func send(name: String, metadata: [String: Any])
}

final class APIAnalyticsEngine: AnalyticsEngine {
    func send(name: String, metadata: [String: Any]) {
        AnalyticsAPI.send(name: name, metadata: metadata)
    }
}

// Extensionで分けることでモジュール内で処理が簡潔できる

// MARK: BookList

extension AnalyticsEvent {
    static let bookListViewed = AnalyticsEvent(name: "bookListViewed")
    
    static func bookListBookAdded(_ book: Book) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "bookList_bookAdded",
            metadata: ["book" : book.name]
        )
    }
    
    static func bookListBookSelected(index: Int) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "bookList_bookSelected",
            metadata: ["index" : "\(index)"]
        )
    }
    
    static func bookListBookDeleted(_ book: Book) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "bookList_bookDeleted",
            metadata: ["book" : book.name]
        )
    }
}

final class BookListViewController: UIViewController {
    private var library: Library
    private let analytics: AnalyticsManager
    
    init(library: Library, analytics: AnalyticsManager) {
        self.library = library
        self.analytics = analytics
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        analytics.log(.bookListViewed)
    }
    
    func addBook(_ book: Book) {
        library.add(book)
        analytics.log(.bookListBookAdded(book))
    }
    
    func deleteBook(at index: Int) {
        guard let book = library.delete(at: index) else {
            return
        }
        analytics.log(.bookListBookDeleted(book))
    }
    
}

// MARK: BookDetail

extension AnalyticsEvent {
    static func bookDetailBookAdded(_ book: Book) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "bookDetail_bookAdded",
            metadata: ["book" : book.name]
        )
    }
    
    // custom initを作成するとXcodeの補完に全部出て来てしまう...
    init(book: Book, count: Int) {
        self.init(
            name: "bookList_bookRead",
            metadata: ["book" : book.name, "read_count": count]
        )
    }
    init(a: String) {
        self.init(name: a)
    }
    init(b: String) {
        self.init(name: b)
    }
    init(c: String) {
        self.init(name: c)
    }
    init(d: String) {
        self.init(name: d)
    }
    init(e: String) {
        self.init(name: e)
    }
    init(f: String) {
        self.init(name: f)
    }
    init(g: String) {
        self.init(name: g)
    }
}

final class BookDetailViewController: UIViewController {
    private var library: Library
    private let analytics: AnalyticsManager
    
    init(library: Library, analytics: AnalyticsManager) {
        self.library = library
        self.analytics = analytics
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addBook(_ book: Book) {
        library.add(book)
        analytics.log(.bookListBookAdded(book))
    }

    func readBook(at index: Int) {
        guard let book = library.read(at: index) else {
            return
        }
        analytics.log(AnalyticsEvent(book: book, count: 1))
    }
}

// MARK: Exmpale

let engine = APIAnalyticsEngine()
let manager = AnalyticsManager(engine: engine)
let collection = Library()

let vc = BookListViewController.init(library: collection, analytics: manager)
vc.addBook(Book(name: "我輩は猫である"))
vc.addBook(Book(name: "三四郎"))
vc.deleteBook(at: 0)

let detailVC = BookDetailViewController.init(library: collection, analytics: manager)
detailVC.addBook(Book(name: "こころ"))
detailVC.readBook(at: 1)
