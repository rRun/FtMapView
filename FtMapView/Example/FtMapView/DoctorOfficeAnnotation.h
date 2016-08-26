//
//  DoctorOfficeAnnotation.h
//  FtMapView
//
//  Created by 何霞雨 on 16/8/26.
//  Copyright © 2016年 hexy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <MapKit/MapKit.h>
#import "FtMapView/BaseMapCluster.h"

@interface DoctorOfficeAnnotation : NSObject<MKAnnotation>

@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *subtitle;

- (id)initWithDictionary:(NSDictionary *)dictionary;


@end
