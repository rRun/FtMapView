//
//  FtViewController.h
//  FtMapView
//
//  Created by hexy on 08/22/2016.
//  Copyright (c) 2016 hexy. All rights reserved.
//

@import UIKit;
#import "FtMapView/BaseMapView.h"
#import "FtMapView/Locator.h"

@interface FtViewController : UIViewController

@property (strong, nonatomic) IBOutlet BaseMapView * mapView;

@property (weak, readonly, nonatomic) NSString * seedFileName; // abstract
@property (weak, readonly, nonatomic) NSString * pictoName; // abstract
@property (weak, readonly, nonatomic) NSString * clusterPictoName; // abstract


@end
