//
//  CommentViewController.swift
//  Instagram
//
//  Created by 関智矢 on 2021/01/07.
//  Copyright © 2021 tomoya.seki. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD

class CommentViewController: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewHeight: NSLayoutConstraint!
    @IBOutlet weak var textViewContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!

    var postDataId: String!

    fileprivate var currentTextViewHeight: CGFloat = 38.5 //HiraginoSans Fontサイズ15の初期高さ

    // Firestoreのリスナー
    var listener: ListenerRegistration!
    
    // コメントデータを格納する配列
    var commentArray: [CommentData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // textViewのスタイル設定
        textView.layer.borderWidth = 1.0
        textView.layer.borderColor = UIColor(red: 204/255, green: 204/255, blue: 204/255, alpha: 1.0).cgColor
        textView.layer.cornerRadius = 5.0
        textView.layer.masksToBounds = true

        textView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DEBUG_PRING: viewWillAppear")
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        // コメントの取得
        let commentsRef = Firestore.firestore().collection(Const.PostPath).document(postDataId).collection(Const.CommentPath).order(by:"date", descending: true)
        self.listener = commentsRef.addSnapshotListener() { (QuerySnapshot, error) in
            if let error = error {
                print("DEBUG_PRINT: snapshotの取得が失敗しました。 \(error)")
                return
            }
            self.commentArray = QuerySnapshot!.documents.map {document in
                let commentData = CommentData(document: document)
                return commentData
            }
            // TableViewの表示を更新する
            self.tableView.reloadData()
        }
    }

    // キーボードが現れたら画面の位置も一緒にあげる
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height - 20
            } else {
                let suggestionHeight = self.view.frame.origin.y + keyboardSize.height
                self.view.frame.origin.y -= suggestionHeight
            }
        }
    }
    
    // キーボードが隠れたら画面の位置も元に戻す
    @objc func keyboardWillHide() {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    // タップでキーボードを隠す
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let contentHeight = self.textView.contentSize.height
        
        // @38.0: textViewの高さの最小値
        // @80.0: textViewの高さの最大値
        if 38.0 <= contentHeight && contentHeight <= 80.0 {
            self.textView.translatesAutoresizingMaskIntoConstraints = true
            self.textView.sizeToFit()
            self.textView.isScrollEnabled = false
            let resizedHeight = self.textView.frame.size.height
            self.textViewHeight.constant = resizedHeight
            // @x: 30（左のマージン）
            // @y: 10（上のマージン）
            // @width: self.view.frame.width - 120(左右のマージン)
            // @height: sizeToFit()後の高さ
            self.textView.frame = CGRect(x: 30, y: 10, width: self.view.frame.width - 120, height: resizedHeight)
     
            if resizedHeight > currentTextViewHeight {
                let addingHeight = resizedHeight - currentTextViewHeight
                self.textViewContainerHeight.constant += addingHeight
                currentTextViewHeight = resizedHeight
            } else if resizedHeight < currentTextViewHeight {
                let subtractingHeight = currentTextViewHeight - resizedHeight
                self.textViewContainerHeight.constant -= subtractingHeight
                currentTextViewHeight = resizedHeight
            }
        } else {
            self.textView.isScrollEnabled = true
            self.textViewHeight.constant = currentTextViewHeight
            self.textView.frame = CGRect(x: 30, y: 10, width: self.view.frame.width - 120, height: currentTextViewHeight)
        }
    }

    @IBAction func handleSubmitButton(_ sender: Any) {
        print("DEBUG_PRINT: 送信ボタンがタップされました。")
        
        // commentに更新データを書き込む
        if textView.text != "" {
            let postRef = Firestore.firestore().collection(Const.PostPath).document(postDataId).collection(Const.CommentPath).document()
            // FireStoreにコメントを保存する
            let name = Auth.auth().currentUser?.displayName
            let postDic = [
                "name": name!,
                "comment": textView.text!,
                "date": FieldValue.serverTimestamp(),
            ] as [String: Any]
            postRef.setData(postDic)
            
            // 投稿を終了する
            self.textView.text = ""
            self.view.endEditing(true)
        }
    }

    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commentArray.count
    }

    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)
        
        cell.textLabel?.numberOfLines = 0

        let comment =  commentArray[indexPath.row]
        cell.textLabel?.text = "\(comment.name!) : \(comment.comment!)"
        
        return cell
    }

    @IBAction func handleBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
