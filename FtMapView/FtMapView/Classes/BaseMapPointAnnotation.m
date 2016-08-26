//
//  BaseMapPointAnnotation.m
//  Pods
//
//  Created by 何霞雨 on 16/8/22.
//
//

#import "BaseMapPointAnnotation.h"


@implementation BaseMapPointAnnotation

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation {
    self = [super init];
    if (self) {
        _mapPoint = MKMapPointForCoordinate(annotation.coordinate);
        _annotation = annotation;
    }
    return self;
}

@end
