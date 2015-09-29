//
//  ViewController.swift
//  AFNetworking tvOS Example
//
//  Created by Kevin Harwood on 9/24/15.
//  Copyright © 2015 Alamofire. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet var collectionView: UICollectionView!
    var gravatars: [Gravatar] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        for _ in 1...100 {
            let gravatar = Gravatar(
                emailAddress: NSUUID().UUIDString,
                defaultImage: Gravatar.DefaultImage.Identicon,
                forceDefault: true
            )

            gravatars.append(gravatar)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gravatars.count
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CollectionViewCell", forIndexPath: indexPath) as! CollectionViewCell
        cell.update(forGravatar: gravatars[indexPath.item])
        return cell
    }

    func collectionView(collectionView: UICollectionView, canFocusItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

}

class CollectionViewCell : UICollectionViewCell {
    @IBOutlet var avatarView: UIImageView!

    override func prepareForReuse() {
        self.avatarView.image = nil
    }

    func update(forGravatar gravatar:Gravatar) {
        self.avatarView.setImageWithURL(gravatar.URL(size: self.avatarView.bounds.size.width))
    }
}

