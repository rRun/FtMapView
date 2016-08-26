//
//  BaseMapAnnotation.m
//  Pods
//
//  Created by 何霞雨 on 16/8/22.
//
//

#import "BaseMapAnnotation.h"

BOOL BaseCoordinate2DIsOffscreen(CLLocationCoordinate2D coord) {
    return (coord.latitude == kBaseCoordinate2DOffscreen.latitude && coord.longitude == kBaseCoordinate2DOffscreen.longitude);
}

@implementation BaseMapAnnotation
@synthesize cluster = _cluster;

-(instancetype)init{
    self = [super init];
    if (self) {
        
        _cluster = nil;
        self.coordinate = kBaseCoordinate2DOffscreen;
        _type = BaseAnnotationTypeUnknown;
        _shouldBeRemovedAfterAnimation = NO;
        
    }
    return self;
}

- (void)reset {
    self.cluster = nil;
    self.coordinate = kBaseCoordinate2DOffscreen;
}


#pragma mark - setter and getter

- (void)setCluster:(BaseMapCluster *)cluster {
    [self willChangeValueForKey:@"title"];
    [self willChangeValueForKey:@"subtitle"];
    _cluster = cluster;
    [self didChangeValueForKey:@"subtitle"];
    [self didChangeValueForKey:@"title"];
}

- (BaseMapCluster *)cluster {
    return _cluster;
}

- (NSString *)title {
    return self.cluster.title;
}

- (NSString *)subtitle {
    return self.cluster.subtitle;
}

- (NSArray *)originalAnnotations {
    NSAssert(self.cluster != nil, @"This annotation should have a cluster assigned!");
    return self.cluster.originalAnnotations;
}

@end
