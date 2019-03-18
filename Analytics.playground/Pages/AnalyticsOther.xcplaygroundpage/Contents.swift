import UIKit

// MARK: ViewControllerから送られるイベント

protocol BookListViewControllerDelegate {
    func didBookAdd(_ book: Book)
    func didBookDelete(_ book: Book)
}

protocol BookDetailViewControllerDelegate {
    func didBookAdd(_ book: Book)
    func didBookRead(_ book: Book)
}

// MARK: ログを送るAnalyticsEngine

// 独自のAPIへログを送る
struct MyAnalyticsWrapper {
    func didBookAdd(_ book: Book) {
        AnalyticsAPI.send(name: "bookAdded", metadata: ["book": book.name])
    }
}
extension MyAnalyticsWrapper: BookListViewControllerDelegate {
    func didBookDelete(_ book: Book) {
        AnalyticsAPI.send(name: "bookDeleted", metadata: ["book": book.name])
    }
}
extension MyAnalyticsWrapper: BookDetailViewControllerDelegate {
    func didBookRead(_ book: Book) {
        AnalyticsAPI.send(name: "bookRead", metadata: ["book": book.name])
    }
}

// Firebaseへログを送る
struct FirebaseWrapper {
    func didBookAdd(_ book: Book) {
        let log = """
        EventName: bookAdded
        AnalyticsParameterItemID: \(UUID().uuidString)
        AnalyticsParameterItemName: book
        AnalyticsParameterContentType: name
        AnalyticsParameterValue: \(book.name)
        """
        print(log)
    }
}
extension FirebaseWrapper: BookListViewControllerDelegate {
    func didBookDelete(_ book: Book) {
        let log = """
        EventName: bookDeleted
        AnalyticsParameterItemID: \(UUID().uuidString)
        AnalyticsParameterItemName: book
        AnalyticsParameterContentType: name
        AnalyticsParameterValue: \(book.name)
        """
        print(log)
    }
}
extension FirebaseWrapper: BookDetailViewControllerDelegate {
    func didBookRead(_ book: Book) {
        let log = """
        EventName: bookRead
        AnalyticsParameterItemID: \(UUID().uuidString)
        AnalyticsParameterItemName: book
        AnalyticsParameterContentType: name
        AnalyticsParameterValue: \(book.name)
        """
        print(log)
    }
}

// MARK: BookListViewControllerのイベントのログを複数のAnalyticsへ送るためのComposite Wrapper

struct BookListCompositeWrapper: BookListViewControllerDelegate {
    
    private let wrappers: [BookListViewControllerDelegate]
    
    init(_ wrappers: BookListViewControllerDelegate...) {
        self.wrappers = wrappers
    }
    
    func didBookAdd(_ book: Book) {
        wrappers.forEach { $0.didBookAdd(book) }
    }
    
    func didBookDelete(_ book: Book) {
        wrappers.forEach { $0.didBookDelete(book) }
    }
}

// MARK: BookListDetailControllerのイベントのログを複数のAnalyticsへ送るためのComposite Wrapper

struct BookDetailCompositeWrapper: BookDetailViewControllerDelegate {
    
    private let wrappers: [BookDetailViewControllerDelegate]

    init(_ wrappers: BookDetailViewControllerDelegate...) {
        self.wrappers = wrappers
    }
    
    func didBookAdd(_ book: Book) {
        wrappers.forEach { $0.didBookAdd(book) }
    }
    
    func didBookRead(_ book: Book) {
        wrappers.forEach { $0.didBookRead(book) }
    }
}

// MARK: BookList

final class BookListViewController: UIViewController {
    private var library: Library
    
    var delegate: BookListViewControllerDelegate? = nil
    
    init(library: Library) {
        self.library = library
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addBook(_ book: Book) {
        library.add(book)
        delegate?.didBookAdd(book)
    }
    
    func deleteBook(at index: Int) {
        guard let book = library.delete(at: index) else {
            return
        }
        delegate?.didBookDelete(book)
    }
}

// MARK: BookDetail

final class BookDetailViewController: UIViewController {
    private var library: Library

    var delegate: BookDetailViewControllerDelegate? = nil

    init(library: Library) {
        self.library = library
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addBook(_ book: Book) {
        library.add(book)
        delegate?.didBookAdd(book)
    }
    
    func readBook(at index: Int) {
        guard let book = library.read(at: index) else {
            return
        }
        delegate?.didBookRead(book)
    }
}

// MARK: Exmpale

let bookListCompositeWrapper
    = BookListCompositeWrapper(MyAnalyticsWrapper(), FirebaseWrapper())

let collection = Library()

let vc = BookListViewController(library: collection)
vc.delegate = bookListCompositeWrapper
vc.addBook(Book(name: "我輩は猫である"))
vc.addBook(Book(name: "三四郎"))
vc.deleteBook(at: 0)

let bookDetailCompositeWrapper
    = BookDetailCompositeWrapper(MyAnalyticsWrapper(), FirebaseWrapper())

let detailVC = BookDetailViewController(library: collection)
detailVC.delegate = bookDetailCompositeWrapper
detailVC.delegate = bookDetailCompositeWrapper
detailVC.addBook(Book(name: "こころ"))
detailVC.readBook(at: 1)



