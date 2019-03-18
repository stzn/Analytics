import UIKit

// ログデータモデル

struct AnalyticsEvent {
    var name: String
    var metadata: [String: Any] = [:]
    init(name: String, metadata: [String: Any] = [:]) {
        self.name = name
        self.metadata = metadata
    }
}

// MARK: AnalyticsEngine(ログを送る)

protocol AnalyticsEngine: class {
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
        let event = AnalyticsEvent(name: "bookListViewed")
        analytics.log(event)
    }
    
    func addBook(book: Book) {
        library.add(book)
        let event = AnalyticsEvent(name: "bookAdded", metadata: ["book": book.name])
        analytics.log(event)
    }
    
    func deleteBook(at index: Int) {
        guard let book = library.delete(at: index) else {
            return
        }
        let event = AnalyticsEvent(name: "bookDeleted", metadata: ["book": book.name])
        analytics.log(event)
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

    func addBook(book: Book) {
        library.add(book)
        
        // タイプミス！！！
        let event = AnalyticsEvent(name: "bookOdded", metadata: ["book": book.name])
        analytics.log(event)
    }
}

// MARK: Exmpale

let engine = APIAnalyticsEngine()
let manager = AnalyticsManager(engine: engine)
let collection = Library()

let vc = BookListViewController.init(library: collection, analytics: manager)
vc.addBook(book: Book(name: "我輩は猫である"))
vc.addBook(book: Book(name: "三四郎"))
vc.deleteBook(at: 0)
