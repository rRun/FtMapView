//
//  BaseMapView.h
//  Pods
//
//  Created by 何霞雨 on 16/8/22.
//
//

#import <MapKit/MapKit.h>
#import "BaseMapCluster.h"
#import "BaseMapAnnotation.h"

@protocol BaseClusterMapViewDelegate ;
@interface BaseMapView : MKMapView

@property (nonatomic, readonly) NSArray * displayedAnnotations;//节点数组
@property (nonatomic, readonly) NSArray * displayedBaseAnnotations;//集群节点

/**
 *  添加大头钉——已不可用
 *
 *  @param annotation
 */
- (void)addAnnotation:(id<MKAnnotation>)annotation NS_UNAVAILABLE;
- (void)addAnnotations:(NSArray<id<MKAnnotation>> *)annotations NS_UNAVAILABLE;

/**
 *  添加大头钉
 *
 *  @param annotation
 */
- (void)addBaseAnnotation:(id<MKAnnotation>)annotation;
- (void)addBaseAnnotations:(NSArray *)annotations;

/**
 *  移除大头钉
 *
 *  @param annotation
 */
- (void)removeBaseAnnotation:(id<MKAnnotation>)annotation;
- (void)removeBaseAnnotations:(NSArray *)annotations;

/**
 *  移除所有的大头钉，并添加新的大头钉
 *
 *  @param annotations
 */
- (void)setAnnotations:(NSArray *)annotations;

/**
 *  选中大头钉
 *
 *  @param annotation 大头钉model
 *  @param animated   是否动画
 */
- (void)selectBaseAnnotation:(BaseMapAnnotation *)annotation animated:(BOOL)animated;


@end

@protocol BaseClusterMapViewDelegate <MKMapViewDelegate>

@optional
// default: 32
- (NSInteger)numberOfClustersInMapView:(BaseMapView *)mapView;

// default: same as returned by mapView:viewForAnnotation:
- (MKAnnotationView *)mapView:(BaseMapView *)mapView viewForClusterAnnotation:(id <MKAnnotation>)annotation;

// default: YES
- (BOOL)shouldShowSubtitleForClusterAnnotationsInMapView:(BaseMapView *)mapView;

// This parameter emphasize the discrimination of annotations which are far away from the center of mass. default: 1.0 (no discrimination applied)
- (double)clusterDiscriminationPowerForMapView:(BaseMapView *)mapView;

// default : @"%d elements"
- (NSString *)clusterTitleForMapView:(BaseMapView *)mapView;

- (void)clusterAnimationDidStopForMapView:(BaseMapView *)mapView;

- (void)mapViewDidFinishClustering:(BaseMapView *)mapView;


@end

