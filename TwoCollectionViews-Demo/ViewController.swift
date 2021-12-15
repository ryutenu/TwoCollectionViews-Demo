//
//  ViewController.swift
//  TwoCollectionViews-Demo
//
//  Created by Alan Liu on 2021/12/15.
//

import UIKit
import Combine

class ViewController: UIViewController {
    
    fileprivate let screenWidth = UIScreen.main.bounds.size.width
    
    fileprivate let screenHeight = UIScreen.main.bounds.size.height
    
    let model = Model()
    
    fileprivate var mainCollectionView: UICollectionView!
    
    fileprivate var thumbCollectionView: UICollectionView!
    
    fileprivate var thumCollectionViewActive: Bool = true
    
    @Published var collectionViewIndex: Int? = 0
    
    private var validateCollectionViewIndex : AnyPublisher<Int?, Never> {
        return $collectionViewIndex
            .debounce(for: 0.4, scheduler: RunLoop.main)
            .removeDuplicates()
            .flatMap{ (collectionViewIndex) -> AnyPublisher<Int?, Never> in
                Future<Int?, Never> { (promise) in
                    guard let collectionViewIndex = collectionViewIndex else {
                        promise(.success(nil))
                        return
                    }
                    if 0 ... self.model.colors.count ~= collectionViewIndex {
                        promise(.success(collectionViewIndex))
                    } else {promise(.success(nil))}
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpMainCollectionView()
        setUpThumCollectionView()
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let displayDataIndex = model.colors.count
        let indexPath = IndexPath(row: displayDataIndex - 1, section: 0)
        thumbCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
        mainCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
    }
    
    private func bind() {
        _ = $collectionViewIndex
            .subscribe(on: RunLoop.main)
            .sink(receiveCompletion: { (completion) in print("validatedCollectionViewIndex.receiveCompletion: \(completion)") }, receiveValue: { [weak self] (value) in
                guard let value = value else {return}
                print("validatedCollectionViewIndex.receiveValue: \(String(describing: value))")
                self?.mainCollectionView.selectItem(at: IndexPath(row: value, section: 0), animated: false, scrollPosition: .centeredHorizontally)
            })
    }
    
    func setUpMainCollectionView() {
        let mainLayout = UICollectionViewFlowLayout()
        mainLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        mainLayout.minimumLineSpacing = 0
        mainLayout.minimumInteritemSpacing = 0
        mainLayout.itemSize = CGSize(width: screenWidth, height: screenHeight)
        mainLayout.scrollDirection = .horizontal
        let width = self.view.frame.size.width
        let height = self.view.frame.size.height
        mainCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: width, height: height), collectionViewLayout: mainLayout)
        mainCollectionView.isPagingEnabled = true
        mainCollectionView.isScrollEnabled = true
        mainCollectionView.alwaysBounceVertical = false
        mainCollectionView.showsHorizontalScrollIndicator = false
        mainCollectionView.showsVerticalScrollIndicator = false
        mainCollectionView.backgroundColor = UIColor.white
        mainCollectionView.register(MainCollectionViewCell.self, forCellWithReuseIdentifier: "mainCell")
        mainCollectionView.delegate = self
        mainCollectionView.dataSource = self
        self.view.addSubview(mainCollectionView)
    }
    
    func setUpThumCollectionView() {
        let thumbLayout = UICollectionViewFlowLayout()
        thumbLayout.sectionInset = UIEdgeInsets(top: 0, left: screenWidth * 0.5, bottom: 0, right: screenWidth * 0.4)
        thumbLayout.minimumLineSpacing = 0
        thumbLayout.minimumInteritemSpacing = 0
        thumbLayout.itemSize = CGSize(width: screenWidth * 0.1, height: screenHeight * 0.1)
        let width = self.view.frame.size.width
        let height = self.view.frame.size.height
        thumbCollectionView = UICollectionView(frame: CGRect(x: 0, y: (height * 0.9) - 25, width: width, height: height * 0.1 ), collectionViewLayout: thumbLayout)
        thumbLayout.scrollDirection = .horizontal
        thumbLayout.minimumLineSpacing = 0
        thumbCollectionView.alwaysBounceVertical = false
        thumbCollectionView.showsHorizontalScrollIndicator = false
        thumbCollectionView.showsVerticalScrollIndicator = false
        thumbCollectionView.backgroundColor = .darkGray
        thumbCollectionView.register(ThumbnailCollectionViewCell.self, forCellWithReuseIdentifier: "thumCell")
        thumbCollectionView.delegate = self
        thumbCollectionView.dataSource = self
        self.view.addSubview(thumbCollectionView)
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == thumbCollectionView {
            mainCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
            thumbCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.mainCollectionView {
            let partitems = model.colors
            return partitems.count
        } else {
            let partitems = model.colors
            return partitems.count
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.mainCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "mainCell",for: indexPath as IndexPath) as! MainCollectionViewCell
            cell.backgroundColor = model.colors[indexPath.row]
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "thumCell",for: indexPath as IndexPath) as! ThumbnailCollectionViewCell
            cell.backgroundColor = model.colors[indexPath.row]
            return cell
        }
    }
}

extension ViewController {
    func findCenterIndex() {
        let center = self.view.convert(self.thumbCollectionView.center, to: self.thumbCollectionView)
        let collectionViewIndexpath:IndexPath? = thumbCollectionView.indexPathForItem(at: center)
        collectionViewIndex = collectionViewIndexpath?.row
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == mainCollectionView {
            thumbCollectionView.contentOffset.x = mainCollectionView.contentOffset.x/10
        } else if scrollView == thumbCollectionView {
            self.findCenterIndex()
        }
    }
}

class MainCollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ThumbnailCollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class Model {
    let colors:Array<UIColor> = [ UIColor.white, UIColor.lightGray, UIColor.cyan, UIColor.white, UIColor.lightGray, UIColor.cyan, UIColor.white, UIColor.lightGray, UIColor.cyan, UIColor.white]
}
