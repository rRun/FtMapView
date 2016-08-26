//
//  BaseMapPointAnnotation.h
//  Pods
//
//  Created by 何霞雨 on 16/8/22.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface BaseMapPointAnnotation : NSObject

@property (nonatomic, readonly) MKMapPoint mapPoint;
@property (nonatomic, readonly) id<MKAnnotation> annotation;

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation;

@end
