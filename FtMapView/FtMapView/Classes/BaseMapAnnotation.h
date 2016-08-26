//
//  BaseMapAnnotation.h
//  Pods
//
//  Created by 何霞雨 on 16/8/22.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "BaseMapCluster.h"


#define kBaseCoordinate2DOffscreen CLLocationCoordinate2DMake(85.0, 179.0) // this coordinate puts the annotation on the top right corner of the map. We use this instead of kCLLocationCoordinate2DInvalid so that we don't mess with MapKit's KVO weird behaviour that removes from the map the annotations whose coordinate was set to kCLLocationCoordinate2DInvalid.


BOOL BaseCoordinate2DIsOffscreen(CLLocationCoordinate2D coord);

typedef enum {
    
    BaseAnnotationTypeUnknown = 0,//未知
    BaseAnnotationTypeLeaf = 1,//根节点
    BaseAnnotationTypeCluster = 2//父节点
    
} BaseAnnotationType;


@interface BaseMapAnnotation : NSObject<MKAnnotation>

@property (nonatomic) BaseAnnotationType type;//当前节点类型
@property (nonatomic) CLLocationCoordinate2D coordinate;//当前定位坐标

@property (nonatomic) BOOL shouldBeRemovedAfterAnimation;//在动画后移除
@property (weak, nonatomic, readonly) NSArray * originalAnnotations;// 这个节点下还有很多子节点

@property (nonatomic, weak) BaseMapCluster * cluster;//集群管理器

- (void)reset;//重置

@end
