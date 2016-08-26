//
//  MapViewUtil.h
//  FtMapView
//
//  Created by 何霞雨 on 16/8/25.
//  Copyright © 2016年 hexy. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MKMapView (MapViewUtil)
- (void)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated;
@end
