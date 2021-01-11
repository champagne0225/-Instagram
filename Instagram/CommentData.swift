//
//  CommentData.swift
//  Instagram
//
//  Created by 関智矢 on 2021/01/09.
//  Copyright © 2021 tomoya.seki. All rights reserved.
//

import UIKit
import Firebase

class CommentData: NSObject {
    var id: String
    var name: String?
    var comment: String?
    var date: Date?

    init(document: QueryDocumentSnapshot) {
        self.id = document.documentID
        
        let postDic = document.data()
        
        self.name = postDic["name"] as? String
        
        self.comment = postDic["comment"] as? String
        
        let timestamp = postDic["date"] as? Timestamp
        self.date = timestamp?.dateValue()
    }
}
