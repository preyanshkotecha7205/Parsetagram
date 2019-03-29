//
//  FeedViewController.swift
//  Parstagram
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    let commentBar = MessageInputBar()
    var showCommentBar = false
    var selectedPost: PFObject!
    var posts = [PFObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.keyboardDismissMode = .interactive
        
        commentBar.inputTextView.placeholder = "Add a comment. . ."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        
        getPosts()
        // Do any additional setup after loading the view.
    }
    
    @objc func keyboardWillBeHidden(note: Notification) {
        commentBar.inputTextView.text = nil
        showCommentBar = false
        becomeFirstResponder()
    }
    
    override var inputAccessoryView: UIView? {
        return commentBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return showCommentBar
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        // Create Comment
        let comment = PFObject(className: "Comments")
        
        comment["text"] = text
        comment["post"] = selectedPost
        comment["author"] = PFUser.current()!
         
        selectedPost.add(comment, forKey: "comments")
         
        selectedPost.saveInBackground { (success, error) in
            if success {
                print("comment saved")
            } else {
                print("error saving comment")
            }
        }
        
        tableView.reloadData()
        
        // Clear and dismiss input bar
        commentBar.inputTextView.text = nil
        showCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
    }
    
    @IBAction func onLogoutButton(_ sender: Any) {
        PFUser.logOut()
        
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(withIdentifier: "LoginViewController")
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.window?.rootViewController = loginViewController
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        getPosts()
        self.tableView.reloadData()
    }
    
    func getPosts(){
        let query = PFQuery(className: "Post")
        query.includeKeys(["author", "comments", "comments.author"])
        query.limit = 20
        
        query.findObjectsInBackground { (posts, error) in
            if posts != nil {
                self.posts = posts!
                self.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == comments.count + 1{
            showCommentBar = true
            becomeFirstResponder()
            commentBar.inputTextView.becomeFirstResponder()
            selectedPost = post
        }
       
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        return comments.count + 2
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == 0 {
            // Post Cell
            let cell = tableView.dequeueReusableCell(withIdentifier: Cell.PostCell.rawValue) as! PostCell
            
            let user = post["author"] as! PFUser
            let imageFile = post["image"] as! PFFileObject
            let url = URL(string: imageFile.url!)!
            
            cell.usernameLabel.text = user.username
            cell.commentLabel.text = (post["caption"] as! String)
            cell.postImage.af_setImage(withURL: url)
            
            return cell
        } else if indexPath.row <= comments.count {
            // Comment Cell
            let cell = tableView.dequeueReusableCell(withIdentifier: Cell.CommentCell.rawValue) as! CommentCell
            
            let comment = comments[indexPath.row-1]
            
            let user = comment["author"] as! PFUser
            cell.userNameLabel.text = user.username
            cell.commentLabel.text = comment["text"] as? String
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: Cell.AddCommentCell.rawValue)!
            return cell
        }
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
