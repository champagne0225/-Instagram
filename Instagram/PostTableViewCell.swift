//
//  PostTableViewCell.swift
//  Instagram
//
//  Created by 関智矢 on 2021/01/06.
//  Copyright © 2021 tomoya.seki. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

class PostTableViewCell: UITableViewCell {

    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var commentButton: UIButton!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var commentViewButton: UIButton!
    
    // 投稿データを格納する配列
    var commentArray: [CommentData] = []

    // Firestoreのリスナー
    var listener: ListenerRegistration!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        self.commentLabel.isHidden = true
        self.commentViewButton.isHidden = true
    }
    
    // PostDataの内容をセルに表示
    func setPostData(_ postData: PostData) {
        // 画像の表示
        postImageView.sd_imageIndicator = SDWebImageActivityIndicator.gray
        let imageRef = Storage.storage().reference().child(Const.ImagePath).child(postData.id + ".jpg")
        postImageView.sd_setImage(with: imageRef)
        
        // キャプションの表示
        self.captionLabel.text = "\(postData.name!) : \(postData.caption!)"
        
        // 日時の表示
        self.dateLabel.text = ""
        if let date = postData.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            let dateString = formatter.string(from: date)
            self.dateLabel.text = dateString
        }
        
        // いいね数の表示
        let likeNumber = postData.likes.count
        likeLabel.text = "\(likeNumber)"
        
        // いいねボタンの表示
        if postData.isLiked {
            let buttonImage = UIImage(named: "like_exist")
            self.likeButton.setImage(buttonImage, for: .normal)
        } else {
            let buttonImage = UIImage(named: "like_none")
            self.likeButton.setImage(buttonImage, for: .normal)
        }
        
        // コメントの表示
        let commentsRef = Firestore.firestore().collection(Const.PostPath).document(postData.id).collection(Const.CommentPath).order(by:"date", descending: true)
        self.listener = commentsRef.addSnapshotListener() { (QuerySnapshot, error) in
            if let error = error {
                print("DEBUG_PRINT: snapshotの取得が失敗しました。 \(error)")
                return
            }
            self.commentArray = QuerySnapshot!.documents.map {document in
                let commentData = CommentData(document: document)
                return commentData
            }
            if self.commentArray != [] {
                self.commentLabel.isHidden = false
                self.commentLabel.text = "\(self.commentArray[0].name!) : \(self.commentArray[0].comment!)"
                self.commentViewButton.isHidden = false
                self.commentViewButton.setTitle("コメント\(self.commentArray.count)件をすべて見る", for: .normal)
            }
        }
    }
    
}
