//
//  UserTableViewCell.swift
//  Assignment
//
//  Created by Hieu Vu on 1/8/25.
//

import UIKit
import SDWebImage

class UserTableViewCell: UITableViewCell {
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var imgAvatar: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Make the image view a circle
        imgAvatar.layer.cornerRadius = imgAvatar.frame.size.width / 2
        imgAvatar.clipsToBounds = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Cancel any pending image downloads and reset the image
        imgAvatar.sd_cancelCurrentImageLoad()
        imgAvatar.image = nil
    }
    
    func configure(with user: User) {
        lblUsername.text = user.login
        imgAvatar.image = UIImage(named: "placeholder") // Set placeholder image

        if let url = URL(string: user.avatar_url) {
            // Use sd_setImage directly without assigning to imageLoadTask
            imgAvatar.sd_setImage(
                with: url,
                placeholderImage: UIImage(named: "placeholder"),
                options: [.lowPriority, .avoidAutoCancelImage],
                context: [.imageThumbnailPixelSize: CGSize(width: 150, height: 150)]
            )
        }
    }
}

