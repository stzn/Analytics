import UIKit

// enumで定義したログデータ

enum AnalyticsEvent {
    case bookAdded(Book)
    case bookDeleted(Book)
    case bookRead(Book, count: Int)

    var name: String {
        switch self {
        case .bookAdded:
            return "bookAdded"
        case .bookDeleted:
            return "bookDeleted"
        case .bookRead:
            return "bookRead"
        }
    }
    var metadata: [String: Any] {
        switch self {
        case .bookAdded(let book):
            return ["book": book.name]
        case .bookDeleted(let book):
            return ["book" : book.name]
        case .bookRead(let book, let count):
            return ["book" : book.name, "read_count": count]
        }
    }
}

// MARK: AnalyticsEngine(ログを送る)

protocol AnalyticsEngine: AnyObject {
    func log(named name: String, metadata: [String: Any])
}

final class APIAnalyticsEngine: AnalyticsEngine {
    func log(named name: String, metadata: [String: Any]) {
        AnalyticsAPI.send(name: name, metadata: metadata)
    }
}

// MARK: AnalyticsManger(ViewControllerとAnalyticsEngineの仲介役)

final class AnalyticsManager {
    private let engine: AnalyticsEngine
    init(engine: AnalyticsEngine) {
        self.engine = engine
    }
    func log(_ event: AnalyticsEvent) {
        engine.log(named: event.name, metadata: event.metadata)
    }
}


// MARK: BookListViewController

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
    }
    
    func addBook(_ book: Book) {
        library.add(book)
        analytics.log(.bookAdded(book))
    }
    
    func deleteBook(at index: Int) {
        guard let book = library.delete(at: index) else {
            return
        }
        analytics.log(.bookDeleted(book))
    }
}

// MARK: BookDetailViewController

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
        analytics.log(.bookAdded(book))
    }
    
    func readBook(at index: Int) {
        guard let book = library.read(at: index) else {
            return
        }
        analytics.log(.bookRead(book, count: 1))
    }

}

// MARK: Example

let engine = APIAnalyticsEngine()
let manager = AnalyticsManager(engine: engine)
let collection = Library()

let vc = BookListViewController(library: collection, analytics: manager)
vc.addBook(Book(name: "我輩は猫である"))
vc.addBook(Book(name: "三四郎"))
vc.deleteBook(at: 0)

let detailVC = BookDetailViewController(library: collection, analytics: manager)
detailVC.addBook(Book(name: "こころ"))
detailVC.readBook(at: 1)
