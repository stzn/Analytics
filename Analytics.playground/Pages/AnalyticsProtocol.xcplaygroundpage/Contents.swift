import UIKit

// Protocolで定義

protocol AnalyticsEvent {
    var name: String { get }
    var metadata: [String: Any] { get }
}

// enumでもOK

enum LoginAnalyticsEvent: AnalyticsEvent {
    case loginScreenViewed
    case loginAttempted
    case loginFailed(reason: LoginFailureReason)
    case loginSucceeded
    
    struct LoginFailureReason {
        let description: String
    }
    
    var name: String {
        switch self {
        case .loginScreenViewed, .loginAttempted,
             .loginSucceeded:
            return String(describing: self)
        case .loginFailed:
            return "loginFailed"
        }
    }

    var metadata: [String: Any] {
        switch self {
        case .loginScreenViewed, .loginAttempted,
             .loginSucceeded:
            return [:]
        case .loginFailed(let reason):
            return ["reason" : String(describing: reason)]
        }
    }
}

// structでもOK

struct BookReadErrorAnalyticsEvent: AnalyticsEvent {
    var name: String {
        return "BookReadError"
    }
    var metadata: [String: Any] {
        return ["code": "\(reason.code)",
                "description": reason.description]
    }

    struct Reason {
        let code: Int
        let description: String
    }

    // 独自のイニシャライザを定義して呼び出し側の負担を減らせる
    private let reason: Reason
    init(reason: Reason) {
        self.reason = reason
    }
}

// MARK: AnalyticsEngine

protocol AnalyticsEngine {
    func log(_ event: AnalyticsEvent)
}

final class APIAnalyticsEngine: AnalyticsEngine {
    func log(_ event: AnalyticsEvent) {
        AnalyticsAPI.send(name: event.name, metadata: event.metadata)
    }
}

// ※ Managerは必要ない

// MARK: BookList

struct BookListAnalyticsEvent: AnalyticsEvent {
    var name: String
    var metadata: [String: Any]
    
    private init(name: String, metadata: [String: Any] = [:]) {
        self.name = name
        self.metadata = metadata
    }
    
    static let bookListViewed = BookListAnalyticsEvent(name: "bookListViewed")
    
    static func bookSelected(index: Int) -> BookListAnalyticsEvent {
        return BookListAnalyticsEvent(
            name: "bookSelected",
            metadata: ["index" : "\(index)"]
        )
    }
    
    static func bookAdded(_ book: Book) -> BookListAnalyticsEvent {
        return BookListAnalyticsEvent(
            name: "bookAdded",
            metadata: ["book" : book.name]
        )
    }
    
    static func bookDeleted(_ book: Book) -> BookListAnalyticsEvent {
        return BookListAnalyticsEvent(
            name: "bookDeleted",
            metadata: ["book" : book.name]
        )
    }
}

final class BookListViewController: UIViewController {
    private var library: Library
    private let engine: AnalyticsEngine
    
    init(library: Library, engine: AnalyticsEngine) {
        self.library = library
        self.engine = engine
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        engine.log(BookListAnalyticsEvent.bookListViewed)
    }
    
    func addBook(_ book: Book) {
        library.add(book)
        engine.log(BookListAnalyticsEvent.bookAdded(book))
    }
    
    func deleteBook(at index: Int) {
        guard let book = library.delete(at: index) else {
            return
        }
        engine.log(BookListAnalyticsEvent.bookDeleted(book))
    }
}

// MARK: BookDetail

struct BookDetailAnalyticsEvent: AnalyticsEvent {
    var name: String
    var metadata: [String: Any]
    
    private init(name: String, metadata: [String: Any] = [:]) {
        self.name = name
        self.metadata = metadata
    }
    
    static func bookAdded(_ book: Book) -> BookDetailAnalyticsEvent {
        return BookDetailAnalyticsEvent(
            name: "bookAdded",
            metadata: ["book" : book.name]
        )
    }
    
    static func bookRead(_ book: Book, count: Int) -> BookDetailAnalyticsEvent {
        return BookDetailAnalyticsEvent(
            name: "bookRead",
            metadata: ["book" : book.name, "read_count": count]
        )
    }
}

final class BookDetailViewController: UIViewController {
    private var library: Library
    private let engine: AnalyticsEngine
    
    init(library: Library, engine: AnalyticsEngine) {
        self.library = library
        self.engine = engine
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addBook(_ book: Book) {
        library.add(book)
        engine.log(BookDetailAnalyticsEvent.bookAdded(book))
    }
    
    func readBook(at index: Int) {
        guard let book = library.read(at: index) else {
            return
        }
        engine.log(BookDetailAnalyticsEvent.bookRead(book, count: 1))
    }
}

// MARK: Exmpale

let engine = APIAnalyticsEngine()
let collection = Library()

let vc = BookListViewController(library: collection, engine: engine)
vc.addBook(Book(name: "我輩は猫である"))
vc.addBook(Book(name: "三四郎"))
vc.deleteBook(at: 0)

let detailVC = BookDetailViewController(library: collection, engine: engine)
detailVC.addBook(Book(name: "こころ"))
detailVC.readBook(at: 1)


// 
final class EventStore<Event: AnalyticsEvent> {
    var events: [Event]
    init(_ events: [Event]) {
        self.events = events
    }
    func addEvent(_ event: Event) {
        events.append(event)
    }
}

let book = Book(name: "カラマーゾフの兄弟")
let store = EventStore([BookListAnalyticsEvent.bookAdded(book),
                        BookListAnalyticsEvent.bookListViewed])
store.addEvent(BookListAnalyticsEvent.bookListViewed)
store.addEvent(BookDetailAnalyticsEvent.bookAdded(book))


final class AnyEventStore {
    var events: [AnalyticsEvent]
    init(_ events: [AnalyticsEvent]) {
        self.events = events
    }
    func addEvent(_ event: AnalyticsEvent) {
        events.append(event)
    }
}

var store2 = AnyEventStore([BookListAnalyticsEvent.bookAdded(book),
                        BookDetailAnalyticsEvent.bookAdded(book)])
