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
        return ["code": reason.code,
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

// Protocolを使うとどんどん型が増えていく

//protocol AnalyticsEngine {
//    func log(_ event: AnalyticsEvent)
//}

//final class ProductionAnalyticsEngine: AnalyticsEngine {
//    func log(_ event: AnalyticsEvent) {
//        let name = "Production-\(event.name)"
//        AnalyticsAPI.send(name: name, metadata: event.metadata)
//    }
//}
//
//final class DevAnalyticsEngine: AnalyticsEngine {
//    func log(_ event: AnalyticsEvent) {
//        let name = "Dev-\(event.name)"
//        AnalyticsAPI.send(name: name, metadata: event.metadata)
//    }
//}
//
//final class StagingAnalyticsEngine: AnalyticsEngine {
//    func log(_ event: AnalyticsEvent) {
//        let name = "Staging-\(event.name)"
//        AnalyticsAPI.send(name: name, metadata: event.metadata)
//    }
//}
//final class TestAnalyticsEngine: AnalyticsEngine {
//    func log(_ event: AnalyticsEvent) {
//        let name = "Test-\(event.name)"
//        AnalyticsAPI.send(name: name, metadata: event.metadata)
//    }
//}


// MARK: GenericなStructで定義したAnalyticsEngine(ログを送る)

struct AnalyticsEngine<Event: AnalyticsEvent> {
    let log: (Event) -> Void
    
    init(log: @escaping (Event) -> Void) {
        self.log = log
    }
}

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
    private let engine: AnalyticsEngine<BookListAnalyticsEvent>
    
    init(library: Library, engine: AnalyticsEngine<BookListAnalyticsEvent>) {
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
    private let engine: AnalyticsEngine<BookDetailAnalyticsEvent>
    
    init(library: Library, engine: AnalyticsEngine<BookDetailAnalyticsEvent>) {
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

// すべてのログに付加するPrefix
let prefix = "Production-"

// BookListViewController用のAnalyticsEngine
let bookListEngine = AnalyticsEngine<BookListAnalyticsEvent> { event in
    let name = "\(prefix)\(event.name)"
    AnalyticsAPI.send(name: name, metadata: event.metadata)
}

let collection = Library()

let vc = BookListViewController(library: collection, engine: bookListEngine)
vc.addBook(Book(name: "我輩は猫である"))
vc.addBook(Book(name: "三四郎"))
vc.deleteBook(at: 0)

// BookDetailViewController用のAnalyticsEngine
let bookDetailEngine = AnalyticsEngine<BookDetailAnalyticsEvent> { event in
    let name = "\(prefix)\(event.name)"
    AnalyticsAPI.send(name: name, metadata: event.metadata)
}
let detailVC = BookDetailViewController(library: collection, engine: bookDetailEngine)
detailVC.addBook(Book(name: "こころ"))
detailVC.readBook(at: 1)


// 複数のEventとログを送ることはできない
//struct MultipleAnalyticsEngine<Event: AnalyticsEvent> {
//    static func log(events: [Event]) {
//        events.forEach {
//            AnalyticsAPI.send(name: $0.name, metadata: $0.metadata)
//        }
//    }
//}
//let book = Book(name: "カラマーゾフの兄弟")
//MultipleAnalyticsEngine<BookListAnalyticsEvent>.log(events: [BookListAnalyticsEvent.bookAdded(book),
//                 BookDetailAnalyticsEvent.bookAdded(book)]) // エラー

// Protocolの制約をなくすとをコンパイラのチェックができない
//struct MultipleAnalyticsEngine {
//    static func log(events: [AnalyticsEvent]) {
//        events.forEach {
//            AnalyticsAPI.send(name: $0.name, metadata: $0.metadata)
//        }
//    }
//}
//
//let book = Book(name: "カラマーゾフの兄弟")
//MultipleAnalyticsEngine.log(events: [BookListAnalyticsEvent.bookAdded(book),
//                                     BookListAnalyticsEvent.bookAdded(book)]) // 本当はBookDetailAnalyticsEvent.bookAddedを送りたかった。。。
