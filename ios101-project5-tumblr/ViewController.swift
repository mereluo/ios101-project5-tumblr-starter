//
//  ViewController.swift
//  ios101-project5-tumbler
//

import UIKit
import Nuke

class ViewController: UIViewController, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
        
        let post = posts[indexPath.row]
        
        if let photo = post.photos.first {
            let imageUrl = photo.originalSize.url
            Nuke.loadImage(with: imageUrl, into: cell.postImageView)
        }
        
        cell.summaryLabel.text = post.summary
        
        return cell
    }
    
    @IBOutlet weak var tableView: UITableView!
    private var posts: [Post] = []
    private var blogNames = ["humansofnewyork", "humansofseoul", "humansofparis"]
    private var currentBlogIndex = 0
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        
        // set up pull to refresh
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        fetchPosts(from: blogNames[currentBlogIndex])
    }
    
    @objc func didPullToRefresh() {
        // Move to the next blog (circularly)
        currentBlogIndex = (currentBlogIndex + 1) % blogNames.count
        let nextBlog = blogNames[currentBlogIndex]
        
        print("🔁 Refreshing from: \(nextBlog)")
        fetchPosts(from: nextBlog)
    }
    
    
    func fetchPosts(from blog: String) {
        let url = URL(string: "https://api.tumblr.com/v2/blog/\(blog)/posts/photo?api_key=1zT8CiXGXFcQDyMFG7RtcfGLwTdDjFUJnZzKJaWTmgyK4lKGYk")!
        let session = URLSession.shared.dataTask(with: url) { data, response, error in
            
            DispatchQueue.main.async { [weak self] in
                // Always stop refreshing
                self?.refreshControl.endRefreshing()
            }
            
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (200...299).contains(statusCode) else {
                print("❌ Response error: \(String(describing: response))")
                return
            }
            
            guard let data = data else {
                print("❌ Data is NIL")
                return
            }
            
            do {
                let blog = try JSONDecoder().decode(Blog.self, from: data)
                
                DispatchQueue.main.async { [weak self] in
                    
                    let posts = blog.response.posts
                    self?.posts = posts
                    self?.tableView.reloadData()
                    
                    print("✅ We got \(posts.count) posts!")
                    for post in posts {
                        print("🍏 Summary: \(post.summary)")
                    }
                }
                
            } catch {
                print("❌ Error decoding JSON: \(error.localizedDescription)")
            }
        }
        session.resume()
    }
}
