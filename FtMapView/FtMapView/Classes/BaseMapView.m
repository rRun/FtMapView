//
//  BaseMapView.m
//  Pods
//
//  Created by 何霞雨 on 16/8/22.
//
//

#import "BaseMapView.h"
#import "BaseMapAnnotation.h"
#import "BaseMapPointAnnotation.h"

@interface BaseMapView () {
@private
    __weak id <BaseClusterMapViewDelegate>  _secondaryDelegate;
    BaseMapCluster *                 _rootMapCluster;
    BOOL                           _isAnimatingClusters;
    BOOL                           _shouldComputeClusters;
}

@property (strong, nonatomic) NSMutableArray * clusterAnnotations;
@property (strong, nonatomic) NSMutableArray * clusterAnnotationsToAddAfterAnimation;

- (void)_initElements;
- (BaseMapAnnotation *)_newAnnotationWithCluster:(BaseMapCluster *)cluster ancestorAnnotation:(BaseMapAnnotation *)ancestor;
- (void)_clusterInMapRect:(MKMapRect)rect;
- (NSInteger)_numberOfClusters;
- (BOOL)_annotation:(BaseMapAnnotation *)annotation belongsToClusters:(NSArray *)clusters;
- (void)_handleClusterAnimationEnded;
- (void)_addClusterAnnotations:(NSArray <id <MKAnnotation>> *)annotations;
- (void)_addClusterAnnotation:(id <MKAnnotation>)annotation;
@end

@implementation BaseMapView
#pragma mark - Life S
-(void)awakeFromNib{
    [super awakeFromNib];
    
}
#pragma mark - MKMapView
- (void)addAnnotation:(id<MKAnnotation>)annotation {
    NSAssert(NO, @"Cannot be used for now");
}

- (void)addAnnotations:(NSArray *)annotations {
    NSAssert(NO, @"Cannot be used for now");
}

- (void)addBaseAnnotation:(id<MKAnnotation>)annotation {
    [super addAnnotation:annotation];
}

- (void)addBaseAnnotations:(NSArray *)annotations {
    [super addAnnotations:annotations];
}

- (void)removeBaseAnnotation:(id<MKAnnotation>)annotation {
    [super removeAnnotation:annotation];
}

- (void)removeBaseAnnotations:(NSArray *)annotations {
    [super removeAnnotations:annotations];
}

- (void)selectBaseAnnotation:(BaseMapAnnotation *)annotation animated:(BOOL)animated{
    [super selectAnnotation:annotation animated:animated];
}
- (void)setAnnotations:(NSArray *)annotations{
    [self removeAnnotations:self.annotations];
    
    NSMutableArray * leafClusterAnnotations = [[NSMutableArray alloc] initWithCapacity:annotations.count];
    for (int i = 0; i < annotations.count; i++) {
        BaseMapAnnotation * annotation = [[BaseMapAnnotation alloc] init];
        annotation.type = BaseAnnotationTypeLeaf;
        annotation.coordinate = [annotations[i] coordinate];
        [leafClusterAnnotations addObject:annotation];
    }
    [self _addClusterAnnotations:leafClusterAnnotations];
    double gamma = 1.0; // default value
    if ([_secondaryDelegate respondsToSelector:@selector(clusterDiscriminationPowerForMapView:)]) {
        gamma = [_secondaryDelegate clusterDiscriminationPowerForMapView:self];
    }
    
    NSString * clusterTitle = @"%d elements";
    if ([_secondaryDelegate respondsToSelector:@selector(clusterTitleForMapView:)]) {
        clusterTitle = [_secondaryDelegate clusterTitleForMapView:self];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // use wrapper annotations that expose a MKMapPoint property instead of a CLLocationCoordinate2D property
        NSMutableArray * mapPointAnnotations = [[NSMutableArray alloc] initWithCapacity:annotations.count];
        for (id<MKAnnotation> annotation in annotations) {
            BaseMapPointAnnotation * mapPointAnnotation = [[BaseMapPointAnnotation alloc] initWithAnnotation:annotation];
            [mapPointAnnotations addObject:mapPointAnnotation];
        }
        
        // Setting visibility of cluster annotations subtitle (defaults to YES)
        BOOL shouldShowSubtitle = YES;
        if ([_secondaryDelegate respondsToSelector:@selector(shouldShowSubtitleForClusterAnnotationsInMapView:)]) {
            shouldShowSubtitle = [_secondaryDelegate shouldShowSubtitleForClusterAnnotationsInMapView:self];
        }
        
        _rootMapCluster = [BaseMapCluster rootClusterForAnnotations:mapPointAnnotations gamma:gamma clusterTitle:clusterTitle showSubtitle:shouldShowSubtitle];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _clusterInMapRect:self.visibleMapRect];
            NSPredicate * predicate = [NSPredicate predicateWithFormat:@"%K = nil", NSStringFromSelector(@selector(cluster))];
            NSArray * annotationNotDisplayedAfterClustering = [self.clusterAnnotations filteredArrayUsingPredicate:predicate];
            [self removeAnnotations:annotationNotDisplayedAfterClustering];
            if ([_secondaryDelegate respondsToSelector:@selector(mapViewDidFinishClustering:)]) {
                [_secondaryDelegate mapViewDidFinishClustering:self];
            }
        });
    });

}

#pragma mark - Getters
- (NSArray *)displayedAnnotations {
    return [self annotationsInMapRect:self.visibleMapRect].allObjects;
}

- (NSArray *)displayedBaseAnnotations {
    return [self.displayedAnnotations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [BaseMapAnnotation class]]];
}

#pragma mark - Methods
- (BaseMapAnnotation *)clusterAnnotationForOriginalAnnotation:(id<MKAnnotation>)annotation {
    NSAssert(![annotation isKindOfClass:[BaseMapAnnotation class]], @"Unexpected annotation!");
    for (BaseMapAnnotation * clusterAnnotation in self.displayedAnnotations) {
        if ([clusterAnnotation.cluster isRootClusterForAnnotation:annotation]) {
            return clusterAnnotation;
        }
    }
    return nil;
}

- (void)selectClusterAnnotation:(BaseMapAnnotation *)annotation animated:(BOOL)animated {
    [super selectAnnotation:annotation animated:animated];
}

- (void)addNonClusteredAnnotation:(id<MKAnnotation>)annotation {
    [super addAnnotation:annotation];
}

- (void)addNonClusteredAnnotations:(NSArray *)annotations {
    [super addAnnotations:annotations];
}

- (void)removeNonClusteredAnnotation:(id<MKAnnotation>)annotation {
    [super removeAnnotation:annotation];
}

- (void)removeNonClusteredAnnotations:(NSArray *)annotations {
    [super removeAnnotations:annotations];
}

#pragma mark - Objective-C Runtime and subclassing methods
- (void)setDelegate:(id<BaseClusterMapViewDelegate>)delegate {
    /*
     For an undefined reason, setDelegate is called multiple times. The first time, it is called with delegate = nil
     Therefore _secondaryDelegate may be nil when [_secondaryDelegate respondsToSelector:aSelector] is called (result : NO)
     There is some caching done in order to avoid calling respondsToSelector: too much. That's why if we don't take care the runtime will guess that we always have [_secondaryDelegate respondsToSelector:] = NO
     Therefore we clear the cache by setting the delegate to nil.
     */
    [super setDelegate:nil];
    _secondaryDelegate = delegate;
    [super setDelegate:self];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    BOOL respondsToSelector = [super respondsToSelector:aSelector] || [_secondaryDelegate respondsToSelector:aSelector];
    return respondsToSelector;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([_secondaryDelegate respondsToSelector:aSelector]) {
        return _secondaryDelegate;
    }
    return [super forwardingTargetForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([_secondaryDelegate respondsToSelector:[anInvocation selector]]) {
        [anInvocation invokeWithTarget:_secondaryDelegate];
    } else {
        [super forwardInvocation:anInvocation];
    }
}

#pragma mark - MKMapViewDelegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if (![annotation isKindOfClass:[BaseMapAnnotation class]]) {
        if ([_secondaryDelegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
            return [_secondaryDelegate mapView:self viewForAnnotation:annotation];
        }
        return nil;
    }
    // only leaf clusters have annotations
    if (((BaseMapAnnotation *)annotation).type == BaseAnnotationTypeLeaf
        || ![_secondaryDelegate respondsToSelector:@selector(mapView:viewForClusterAnnotation:)]) {
        if ([_secondaryDelegate respondsToSelector:@selector(mapView:viewForAnnotation:)]) {
            return [_secondaryDelegate mapView:self viewForAnnotation:annotation];
        }
        return nil;
    }
    return [_secondaryDelegate mapView:self viewForClusterAnnotation:annotation];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (_isAnimatingClusters) {
        _shouldComputeClusters = YES;
    } else {
        _isAnimatingClusters = YES;
        [self _clusterInMapRect:self.visibleMapRect];
    }
    for (id<MKAnnotation> annotation in [self selectedAnnotations]) {
        [self deselectAnnotation:annotation animated:YES];
    }
    if ([_secondaryDelegate respondsToSelector:@selector(mapView:regionDidChangeAnimated:)]) {
        [_secondaryDelegate mapView:self regionDidChangeAnimated:animated];
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([_secondaryDelegate respondsToSelector:@selector(mapView:didSelectAnnotationView:)]) {
        [_secondaryDelegate mapView:mapView didSelectAnnotationView:view];
    }
}

#pragma mark - Private
- (void)_initElements {
    _clusterAnnotations = [[NSMutableArray alloc] init];
    _clusterAnnotationsToAddAfterAnimation = [[NSMutableArray alloc] init];
}

-(BaseMapAnnotation *)_newAnnotationWithCluster:(BaseMapCluster *)cluster ancestorAnnotation:(BaseMapAnnotation *)ancestor {
    BaseMapAnnotation * annotation = [[BaseMapAnnotation alloc] init];
    annotation.type = (cluster.numberOfChildren == 1) ? BaseAnnotationTypeLeaf : BaseAnnotationTypeCluster;
    annotation.cluster = cluster;
    annotation.coordinate = (ancestor) ? ancestor.coordinate : cluster.clusterCoordinate;
    return annotation;
}

- (void)_clusterInMapRect:(MKMapRect)rect {
    NSArray * clustersToShowOnMap = [_rootMapCluster find:[self _numberOfClusters] childrenInMapRect:rect];
    
    NSMutableArray * annotationToRemoveFromMap = [[NSMutableArray alloc] init];
    NSMutableArray * annotationToAddToMap = [[NSMutableArray alloc] init];
    NSMutableArray * selfDividingAnnotations = [[NSMutableArray alloc] init];
    NSArray * displayedAnnotation = self.displayedBaseAnnotations;
    for (BaseMapAnnotation * annotation in displayedAnnotation) {
        if ([annotation isKindOfClass:[MKUserLocation class]] || !annotation.cluster) {
            continue;
        }
        BOOL isAncestor = NO;
        for (BaseMapCluster * cluster in clustersToShowOnMap) { // is the current annotation cluster an ancestor of one of the clustersToShowOnMap?
            if (![annotation.cluster isAncestorOf:cluster]) {
                continue;
            }
            [selfDividingAnnotations addObject:annotation];
            isAncestor = YES;
            break;
        }
    }
    
    // Let ancestor annotations divide themselves
    for (BaseMapAnnotation * annotation in selfDividingAnnotations) {
        BaseMapCluster * originalAnnotationCluster = annotation.cluster;
        for (BaseMapCluster * cluster in clustersToShowOnMap) {
            if (![originalAnnotationCluster isAncestorOf:cluster]) {
                continue;
            }
            BaseMapAnnotation * newAnnotation = [self _newAnnotationWithCluster:cluster ancestorAnnotation:annotation];
            [annotationToRemoveFromMap addObject:annotation];
            [annotationToAddToMap addObject:newAnnotation];
        }
    }
    
    // Converge annotations to ancestor clusters
    for (BaseMapCluster * cluster in clustersToShowOnMap) {
        BOOL didAlreadyFindAChild = NO;
        for (__strong BaseMapAnnotation * annotation in displayedAnnotation) {
            if ([annotation isKindOfClass:[MKUserLocation class]] || !annotation.cluster || ![cluster isAncestorOf:annotation.cluster]) {
                continue;
            }
            if (!didAlreadyFindAChild) {
                BaseMapAnnotation * newAnnotation = [[BaseMapAnnotation alloc] init];
                newAnnotation.type = BaseAnnotationTypeCluster;
                newAnnotation.cluster = cluster;
                newAnnotation.coordinate = cluster.clusterCoordinate;
                [self.clusterAnnotationsToAddAfterAnimation addObject:newAnnotation];
            }
            annotation.cluster = cluster;
            annotation.shouldBeRemovedAfterAnimation = YES;
            didAlreadyFindAChild = YES;
        }
    }
    
    [self _addClusterAnnotations:annotationToAddToMap];
    [self removeAnnotations:annotationToRemoveFromMap];
    displayedAnnotation = self.displayedBaseAnnotations;
    [UIView animateWithDuration:0.5f animations:^{
        for (BaseMapAnnotation * annotation in displayedAnnotation) {
            if ([annotation isKindOfClass:[MKUserLocation class]]) {
                continue;
            }
            if (![annotation isKindOfClass:[MKUserLocation class]] && annotation.cluster) {
                NSAssert(!BaseCoordinate2DIsOffscreen(annotation.coordinate), @"annotation.coordinate not valid! Can't animate from an invalid coordinate (inconsistent result)!");
                annotation.coordinate = annotation.cluster.clusterCoordinate;
            }
        }
    } completion:^(BOOL finished) {
        [self _handleClusterAnimationEnded];;
    }];
    
    
    // Add not-yet-annotated clusters
    annotationToAddToMap = [[NSMutableArray alloc] init];
    for (BaseMapCluster * cluster in clustersToShowOnMap) {
        BOOL isAlreadyAnnotated = NO;
        for (BaseMapAnnotation * annotation in displayedAnnotation) {
            if (![annotation isKindOfClass:[MKUserLocation class]]) {
                if ([cluster isEqual:annotation.cluster]) {
                    isAlreadyAnnotated = YES;
                    break;
                }
            }
        }
        if (!isAlreadyAnnotated) {
            BaseMapAnnotation * newAnnotation = [self _newAnnotationWithCluster:cluster ancestorAnnotation:nil];
            [annotationToAddToMap addObject:newAnnotation];
        }
    }
    [self _addClusterAnnotations:annotationToAddToMap];
}

- (NSInteger)_numberOfClusters {
    NSInteger numberOfClusters = 32; // default value
    if ([_secondaryDelegate respondsToSelector:@selector(numberOfClustersInMapView:)]) {
        numberOfClusters = [_secondaryDelegate numberOfClustersInMapView:self];
    }
    return numberOfClusters;
}


- (BOOL)_annotation:(BaseMapAnnotation *)annotation belongsToClusters:(NSArray *)clusters {
    if (!annotation.cluster) {
        return NO;
    }
    for (BaseMapCluster * cluster in clusters) {
        if ([cluster isAncestorOf:annotation.cluster] || [cluster isEqual:annotation.cluster]) {
            return YES;
        }
    }
    return NO;
}

- (void)_handleClusterAnimationEnded {
    NSMutableArray * annotationToRemove = [[NSMutableArray alloc] init];;
    for (BaseMapAnnotation * annotation in self.annotations) {
        if ([annotation isKindOfClass:[MKUserLocation class]]) {
            continue;
        }
        if ([annotation isKindOfClass:[BaseMapAnnotation class]]) {
            if (annotation.shouldBeRemovedAfterAnimation) {
                [annotationToRemove addObject:annotation];
            }
        }
    }
    [self removeAnnotations:annotationToRemove];
    [self _addClusterAnnotations:self.clusterAnnotationsToAddAfterAnimation];
    [self.clusterAnnotationsToAddAfterAnimation removeAllObjects];
    _isAnimatingClusters = NO;
    if (_shouldComputeClusters) { // do one more computation if the user moved the map while animating
        _shouldComputeClusters = NO;
        [self _clusterInMapRect:self.visibleMapRect];
    }
    if ([_secondaryDelegate respondsToSelector:@selector(clusterAnimationDidStopForMapView:)]) {
        [_secondaryDelegate clusterAnimationDidStopForMapView:self];
    }
}

- (void)_addClusterAnnotation:(id<MKAnnotation>)annotation {
    [self.clusterAnnotations addObject:annotation];
    [super addAnnotation:annotation];
}

- (void)_addClusterAnnotations:(NSArray<id<MKAnnotation>> *)annotations {
    [self.clusterAnnotations addObjectsFromArray:annotations];
    [super addAnnotations:annotations];
}

@end
