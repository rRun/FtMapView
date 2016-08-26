//
//  BaseMapCluster.h
//  Pods
//
//  Created by 何霞雨 on 16/8/22.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "BaseMapPointAnnotation.h"

#define BaseMapClusterDiscriminationPrecision 1E-4

@interface BaseMapCluster : NSObject

@property (nonatomic) CLLocationCoordinate2D clusterCoordinate;//集群的定位坐标
@property (weak, nonatomic, readonly) NSString * title;//标题
@property (weak, nonatomic, readonly) NSString * subtitle;//子标题
@property (nonatomic, assign) BOOL showSubtitle;//是否显示字标题

@property (nonatomic, strong) BaseMapPointAnnotation * annotation;//大头钉model
@property (weak, nonatomic, readonly) NSMutableArray * originalAnnotations;//大头钉model的数组

@property (nonatomic, readonly) NSInteger depth;//层次数

/**
 *  初始化
 *
 *  @param annotations  大头钉数组
 *  @param depth        层次
 *  @param mapRect      map的区域
 *  @param gamma
 *  @param clusterTitle
 *  @param showSubtitle
 *
 *  @return
 */
- (id)initWithAnnotations:(NSArray *)annotations atDepth:(NSInteger)depth inMapRect:(MKMapRect)mapRect gamma:(double)gamma clusterTitle:(NSString *)clusterTitle showSubtitle:(BOOL)showSubtitle;

/**
 *  获取当前的root
 *
 *  @param annotations
 *  @param gamma
 *  @param clusterTitle
 *  @param showSubtitle
 *
 *  @return
 */
+ (BaseMapCluster *)rootClusterForAnnotations:(NSArray *)annotations gamma:(double)gamma clusterTitle:(NSString *)clusterTitle showSubtitle:(BOOL)showSubtitle;

/**
 *  在区域范围内找到大头钉数组
 *
 *  @param N
 *  @param mapRect 地图区域
 *
 *  @return
 */
- (NSArray *)find:(NSInteger)N childrenInMapRect:(MKMapRect)mapRect;

/**
 *  获取所有的子节点
 *
 *  @return
 */
- (NSArray *)children;

- (BOOL)isAncestorOf:(BaseMapCluster *)mapCluster;
- (BOOL)isRootClusterForAnnotation:(id<MKAnnotation>)annotation;

- (NSInteger)numberOfChildren;
- (NSArray *)namesOfChildren;

@end
