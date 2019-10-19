import UIKit

/// A view controller that lets you to page between views while
/// showing menu items that scrolls along with the content.
///
/// The data source object is responsible for actually generating the
/// `PagingItem` as well as allocating the view controller that
/// corresponds to each item. See `PagingViewControllerDataSource`.
///
/// After providing a data source you need to call
/// `select(pagingItem:animated:)` to set the initial view controller.
/// You can also use the same method to programmatically navigate to
/// other view controllers.
open class PagingViewController:
  UIViewController,
  UICollectionViewDelegate,
  EMPageViewControllerDataSource,
  EMPageViewControllerDelegate {

  // MARK: Public Properties
  
  /// Determine how users can interact with the page view controller.
  /// _Default: .scrolling_
  public var contentInteraction: PagingContentInteraction = .scrolling {
    didSet {
      configureContentInteraction()
    }
  }
  
  /// The current state of the menu items. Indicates whether an item
  /// is currently selected or is scrolling to another item. Can be
  /// used to get the distance and progress of any ongoing transition.
  public var state: PagingState {
    return pagingController.state
  }
  
  /// The `PagingItem`'s that are currently visible in the collection
  /// view. The items in this array are not necessarily the same as
  /// the `visibleCells` property on `UICollectionView`.
  public var visibleItems: PagingItems {
    return pagingController.visibleItems
  }
  
  /// The data source is responsible for providing the `PagingItem`s
  /// that are displayed in the menu. The `PagingItem` protocol is
  /// used to generate menu items for all the view controllers,
  /// without having to actually allocate them before they are needed.
  /// Use this property when you have a fixed amount of view
  /// controllers. If you need to support infinitely large data
  /// sources, use the infiniteDataSource property instead.
  public weak var dataSource: PagingViewControllerDataSource? {
    didSet {
      configureDataSource()
    }
  }
  
  /// A data source that can be used when you need to support
  /// infinitely large data source by returning the `PagingItem`
  /// before or after a given `PagingItem`. The `PagingItem` protocol
  /// is used to generate menu items for all the view controllers,
  /// without having to actually allocate them before they are needed.
  public weak var infiniteDataSource: PagingViewControllerInfiniteDataSource?
  
  /// Use this delegate to get notified when the user is scrolling or
  /// when an item is selected.
  public weak var delegate: PagingViewControllerDelegate?
  
  /// Use this delegate if you want to manually control the width of
  /// your menu items. Self-sizing cells is not supported at the
  /// moment, so you have to use this if you have a custom cell that
  /// you want to size based on its content.
  public weak var sizeDelegate: PagingViewControllerSizeDelegate? {
    didSet {
      pagingController.sizeDelegate = self
    }
  }
  
  /// A custom collection view layout that lays out all the menu items
  /// horizontally. You can customize the behavior of the layout by
  /// setting the customization properties on `PagingViewController`.
  /// You can also use your own subclass of the layout by defining the
  /// `menuLayoutClass` property.
  public private(set) var collectionViewLayout: PagingCollectionViewLayout

  /// Used to display the menu items that scrolls along with the
  /// content. Using a collection view means you can create custom
  /// cells that display pretty much anything. By default, scrolling
  /// is enabled in the collection view.
  public let collectionView: UICollectionView

  /// Used to display the view controller that you are paging
  /// between. Instead of using UIPageViewController we use a library
  /// called EMPageViewController which fixes a lot of the common
  /// issues with using UIPageViewController.
  public let pageViewController: EMPageViewController

  /// An instance that stores all the customization so that it's
  /// easier to share between other classes.
  public var options: PagingOptions {
    didSet {
      if options.menuLayoutClass != oldValue.menuLayoutClass {
        let layout = createLayout(layout: options.menuLayoutClass.self)
        collectionViewLayout = layout
        collectionViewLayout.options = options
        collectionView.setCollectionViewLayout(layout, animated: false)
      }
      else {
        collectionViewLayout.options = options
      }
      
      pagingController.options = options
    }
  }
  
  // MARK: Private Properties
  
  private let pagingController: PagingController
  private var didLayoutSubviews: Bool = false
  
  private var pagingView: PagingView {
    return view as! PagingView
  }
  
  private enum DataSourceReference {
    case `static`(PagingStaticDataSource)
    case finite(PagingFiniteDataSource)
    case none
  }
  
  /// Used to keep a strong reference to the internal data sources.
  private var dataSourceReference: DataSourceReference = .none
  
  // MARK: Initializers

  /// Creates an instance of `PagingViewController`. You need to call
  /// `select(pagingItem:animated:)` in order to set the initial view
  /// controller before any items become visible.
  public init() {
    self.options = PagingOptions()
    self.pagingController = PagingController(options: options)
    self.pageViewController = EMPageViewController(navigationOrientation: .horizontal)
    self.collectionViewLayout = createLayout(layout: options.menuLayoutClass.self)
    self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
    super.init(nibName: nil, bundle: nil)
    collectionView.delegate = self
    configurePagingController()
    
    // Register default cell
    register(PagingTitleCell.self, forCellWithPagingItemType: PagingTitleItem.self)
  }
  
  public convenience init(viewControllers: [UIViewController]) {
    self.init()
    configureDataSource(for: viewControllers)
  }

  /// Creates an instance of `PagingViewController`.
  ///
  /// - Parameter coder: An unarchiver object.
  required public init?(coder: NSCoder) {
    self.options = PagingOptions()
    self.pagingController = PagingController(options: options)
    self.pageViewController = EMPageViewController(navigationOrientation: .horizontal)
    self.collectionViewLayout = createLayout(layout: options.menuLayoutClass.self)
    self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
    super.init(coder: coder)
    collectionView.delegate = self
    configurePagingController()
  }
  
  // MARK: Public Methods
  
  /// Reload the data for the menu items. This method will not reload
  /// the view controllers.
  open func reloadMenu() {
    var updatedItems: [PagingItem] = []
    
    switch dataSourceReference {
    case let .static(dataSource):
      dataSource.reloadItems()
      updatedItems = dataSource.items
    case let .finite(dataSource):
      dataSource.items = itemsForFiniteDataSource()
      updatedItems = dataSource.items
    default:
      break
    }
    
    if let previouslySelected = state.currentPagingItem,
      let pagingItem = updatedItems.first(where: { $0.isEqual(to: previouslySelected) }) {
      pagingController.reloadMenu(around: pagingItem)
    } else if let firstItem = updatedItems.first {
      pagingController.reloadMenu(around: firstItem)
    } else {
      pagingController.removeAll()
    }
  }
  
  /// Reload data for all the menu items. This will keep the
  /// previously selected item if it's still part of the updated data.
  /// If not, it will select the first item in the list. This method
  /// will not work when using PagingViewControllerInfiniteDataSource
  /// as we then need to know what the initial item should be. You
  /// should use the reloadData(around:) method in that case.
  open func reloadData() {
    var updatedItems: [PagingItem] = []
    
    switch dataSourceReference {
    case let .static(dataSource):
      dataSource.reloadItems()
      updatedItems = dataSource.items
    case let .finite(dataSource):
      dataSource.items = itemsForFiniteDataSource()
      updatedItems = dataSource.items
    default:
      break
    }
    
    if let previouslySelected = state.currentPagingItem,
      let pagingItem = updatedItems.first(where: { $0.isEqual(to: previouslySelected) }) {
      pagingController.reloadData(around: pagingItem)
    } else if let firstItem = updatedItems.first {
      pagingController.reloadData(around: firstItem)
    } else {
      pagingController.removeAll()
    }
  }
  
  /// Reload data around given paging item. This will set the given
  /// paging item as selected and generate new items around it. This
  /// will also reload the view controllers displayed in the page view
  /// controller. You need to use this method to reload data when
  /// using PagingViewControllerInfiniteDataSource as we need to know
  /// the initial item.
  ///
  /// - Parameter pagingItem: The `PagingItem` that will be selected
  /// after the data reloads.
  open func reloadData(around pagingItem: PagingItem) {
    switch dataSourceReference {
    case let .static(dataSource):
      dataSource.reloadItems()
    case let .finite(dataSource):
      dataSource.items = itemsForFiniteDataSource()
    default:
      break
    }
    pagingController.reloadData(around: pagingItem)
  }
  
  /// Selects a given paging item. This need to be called after you
  /// initilize the `PagingViewController` to set the initial
  /// `PagingItem`. This can be called both before and after the view
  /// has been loaded. You can also use this to programmatically
  /// navigate to another `PagingItem`.
  ///
  /// - Parameter pagingItem: The `PagingItem` to be displayed.
  /// - Parameter animated: A boolean value that indicates whether
  /// the transtion should be animated. Default is false.
  open func select(pagingItem: PagingItem, animated: Bool = false) {
    pagingController.select(pagingItem: pagingItem, animated: animated)
  }
  
  /// Selects the paging item at a given index. This can be called
  /// both before and after the view has been loaded.
  ///
  /// - Parameter index: The index of the `PagingItem` to be displayed.
  /// - Parameter animated: A boolean value that indicates whether
  /// the transtion should be animated. Default is false.
  open func select(index: Int, animated: Bool = false) {
    switch dataSourceReference {
    case let .static(dataSource):
      let pagingItem = dataSource.items[index]
      pagingController.select(pagingItem: pagingItem, animated: animated)
    case let .finite(dataSource):
      let pagingItem = dataSource.items[index]
      pagingController.select(pagingItem: pagingItem, animated: animated)
    case .none:
      fatalError("select(index:animated:): You need to set the dataSource property to use this method")
    }
  }
  
  open override func loadView() {
    view = PagingView(
      options: options,
      collectionView: collectionView,
      pageView: pageViewController.view
    )
  }
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    
    #if swift(>=4.2)
    addChild(pageViewController)
    pagingView.configure()
    pageViewController.didMove(toParent: self)
    #else
    addChildViewController(pageViewController)
    pagingView.configure()
    pageViewController.didMove(toParentViewController: self)
    #endif
    
    pageViewController.dataSource = self
    configureContentInteraction()

    if #available(iOS 11.0, *) {
      pageViewController.scrollView.contentInsetAdjustmentBehavior = .never
    }
  }
  
  open override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    // We need generate the menu items when the view appears for the
    // first time. Doing it in viewWillAppear does not work as the
    // safeAreaInsets will not be updated yet.
    if didLayoutSubviews == false {
      didLayoutSubviews = true
      pagingController.viewAppeared()
      
      // Selecting a view controller in the page view triggers the
      // delegate methods even if the view has not appeared yet. This
      // causes problems with the initial state when we select items, so
      // we wait until the view has appeared before setting the delegate.
      pageViewController.delegate = self
    }
  }
  
  open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { context in
      self.pagingController.transitionSize()
    }, completion: nil)
  }
  
  /// Register cell class for paging cell
  /// - Parameter cellClass: paging cell's class
  /// - Parameter pagingItemType: paging item type for specifying cell identifier
  public func register(_ cellClass: AnyClass?, forCellWithPagingItemType pagingItemType: PagingItem.Type) {
    collectionView.register(cellClass, forCellWithReuseIdentifier: String(describing: pagingItemType))
  }
  
  /// Register nib for paging cell
  /// - Parameter nib: paging cell's nib
  /// - Parameter pagingItemType: paging item type for specifying cell identifier
  public func register(_ nib: UINib?, forCellWithPagingItemType pagingItemType: PagingItem.Type) {
    collectionView.register(nib, forCellWithReuseIdentifier: String(describing: pagingItemType))
  }
  
  // MARK: Private Methods
  
  private func configurePagingController() {
    pagingController.collectionView = collectionView
    pagingController.collectionViewLayout = collectionViewLayout
    pagingController.dataSource = self
    pagingController.delegate = self
  }
  
  private func itemsForFiniteDataSource() -> [PagingItem] {
    let numberOfItems = dataSource?.numberOfViewControllers(in: self) ?? 0
    var items: [PagingItem] = []
    
    for index in 0..<numberOfItems {
      if let item = dataSource?.pagingViewController(self, pagingItemAt: index) {
        items.append(item)
      }
    }
    
    return items
  }
  
  private func configureDataSource() {
    let dataSource = PagingFiniteDataSource()
    dataSource.items = itemsForFiniteDataSource()
    dataSource.viewControllerForIndex = { [unowned self] in
      return self.dataSource?.pagingViewController(self, viewControllerAt: $0)
    }
    
    dataSourceReference = .finite(dataSource)
    infiniteDataSource = dataSource
    
    if let firstItem = dataSource.items.first {
      pagingController.select(pagingItem: firstItem, animated: false)
    }
  }
  
  private func configureDataSource(for viewControllers: [UIViewController]) {
    let dataSource = PagingStaticDataSource(viewControllers: viewControllers)
    dataSourceReference = .static(dataSource)
    infiniteDataSource = dataSource
    if let pagingItem = dataSource.items.first {
      pagingController.select(pagingItem: pagingItem, animated: false)
    }
  }
  
  private func configureContentInteraction() {
    switch contentInteraction {
    case .scrolling:
      pageViewController.scrollView.isScrollEnabled = true
    case .none:
      pageViewController.scrollView.isScrollEnabled = false
    }
  }
  
  // MARK: UIScrollViewDelegate
  
  open func scrollViewDidScroll(_ scrollView: UIScrollView) {
    pagingController.menuScrolled()
  }
  
  open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    return
  }
  
  open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    return
  }
  
  open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    return
  }
  
  open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    return
  }
  
  open func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
    return
  }
  
  open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    return
  }
  
  // MARK: UICollectionViewDelegate
  
  open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    pagingController.select(indexPath: indexPath, animated: true)
  }
  
  open func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
    return proposedContentOffset
  }
  
  open func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
    return
  }
  
  open func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
    return
  }
  
  open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    return
  }
  
  open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    return
  }
  
  open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    return
  }
  
  // MARK: EMPageViewControllerDataSource
  
  open func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
    guard
      let dataSource = infiniteDataSource,
      let currentPagingItem = state.currentPagingItem,
      let pagingItem = dataSource.pagingViewController(self, itemBefore: currentPagingItem) else { return nil }
    
    return dataSource.pagingViewController(self, viewControllerFor: pagingItem)
  }
  
  open func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
    guard
      let dataSource = infiniteDataSource,
      let currentPagingItem = state.currentPagingItem,
      let pagingItem = dataSource.pagingViewController(self, itemAfter: currentPagingItem) else { return nil }
    
    return dataSource.pagingViewController(self, viewControllerFor: pagingItem)
  }
  
  // MARK: EMPageViewControllerDelegate
  
  open func em_pageViewController(_ pageViewController: EMPageViewController, isScrollingFrom startingViewController: UIViewController, destinationViewController: UIViewController?, progress: CGFloat) {
    guard let currentPagingItem = state.currentPagingItem else { return }
    let oldState = state
    
    // EMPageViewController will trigger a scrolling event even if the
    // view has not appeared, causing the wrong initial paging item.
    if view.window != nil {
      pagingController.contentScrolled(progress: progress)
      
      if case .selected = oldState {
        if let upcomingPagingItem = state.upcomingPagingItem,
          let destinationViewController = destinationViewController {
          delegate?.pagingViewController(
            self,
            willScrollToItem: upcomingPagingItem,
            startingViewController: startingViewController,
            destinationViewController: destinationViewController)
        }
      } else {
        delegate?.pagingViewController(
          self,
          isScrollingFromItem: currentPagingItem,
          toItem: state.upcomingPagingItem,
          startingViewController: startingViewController,
          destinationViewController: destinationViewController,
          progress: progress)
      }
    }
  }
  
  open func em_pageViewController(_ pageViewController: EMPageViewController, willStartScrollingFrom startingViewController: UIViewController, destinationViewController: UIViewController) {
    if let upcomingPagingItem = state.upcomingPagingItem {
      delegate?.pagingViewController(
        self,
        willScrollToItem: upcomingPagingItem,
        startingViewController: startingViewController,
        destinationViewController: destinationViewController)
    }
    return
  }
  
  open func em_pageViewController(_ pageViewController: EMPageViewController, didFinishScrollingFrom startingViewController: UIViewController?, destinationViewController: UIViewController, transitionSuccessful: Bool) {
    if transitionSuccessful {
      pagingController.contentFinishedScrolling()
    }
    
    if let currentPagingItem = state.currentPagingItem {
      delegate?.pagingViewController(
        self,
        didScrollToItem: currentPagingItem,
        startingViewController: startingViewController,
        destinationViewController: destinationViewController,
        transitionSuccessful: transitionSuccessful)
    }
  }
}

extension PagingViewController: PagingMenuDataSource {
  
  public func pagingItemBefore(pagingItem: PagingItem) -> PagingItem? {
    return infiniteDataSource?.pagingViewController(self, itemBefore: pagingItem)
  }
  
  public func pagingItemAfter(pagingItem: PagingItem) -> PagingItem? {
    return infiniteDataSource?.pagingViewController(self, itemAfter: pagingItem)
  }
  
}

extension PagingViewController: PagingControllerSizeDelegate {
  
  func width(for pagingItem: PagingItem, isSelected: Bool) -> CGFloat {
    return sizeDelegate?.pagingViewController(self, widthForPagingItem: pagingItem, isSelected: isSelected) ?? 0
  }
  
}

extension PagingViewController: PagingMenuDelegate {
  
  public func selectContent(pagingItem: PagingItem, direction: PagingDirection, animated: Bool) {
    guard let dataSource = infiniteDataSource else { return }
    
    switch direction {
    case .forward(true):
      pageViewController.scrollForward(animated: animated, completion: nil)
      pageViewController.view.layoutIfNeeded()
      
    case .reverse(true):
      pageViewController.scrollReverse(animated: animated, completion: nil)
      pageViewController.view.layoutIfNeeded()
      
    default:
      pageViewController.selectViewController(
        dataSource.pagingViewController(self, viewControllerFor: pagingItem),
        direction: direction.pageViewControllerNavigationDirection,
        animated: animated,
        completion: nil
      )
    }
  }
  
  public func removeContent() {
    pageViewController.removeAllViewControllers()
  }
  
}
