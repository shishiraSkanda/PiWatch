//
//  EventTableViewCell.swift
//  PiWatch
//
//  Created by Priyanka Gopakumar on 15/11/2016.
//  Copyright © 2016 Priyanka. All rights reserved.
//

/*
 A custom cell design for the History table view to represent information for an event.
 A date and time are used to describe the event in the table. The attributes specified 
 are thus a dateLabel and a timeLabel.
 */
import UIKit

class EventTableViewCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
