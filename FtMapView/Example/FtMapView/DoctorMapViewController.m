//
//  DoctorMapViewController.m
//  FtMapView
//
//  Created by 何霞雨 on 16/8/25.
//  Copyright © 2016年 hexy. All rights reserved.
//

#import "DoctorMapViewController.h"

#import "FtMapView/BaseMapView.h"
#import "FtMapView/Locator.h"

#import "MKMapView+MapViewUtil.h"

#import "DoctorOfficeAnnotationView.h"

@interface DoctorMapViewController ()<BaseClusterMapViewDelegate>{
    BOOL isCloseView;
}

@property (strong, nonatomic) IBOutlet BaseMapView * mapView;
@property (weak, nonatomic) IBOutlet UIButton *locateBtn;

@property (weak, nonatomic) IBOutlet UIView *officeInfoView;
@property (weak, nonatomic) IBOutlet UILabel *doctorOfficeName;
@property (weak, nonatomic) IBOutlet UILabel *ditance;
@property (weak, nonatomic) IBOutlet UILabel *address;
@property (weak, nonatomic) IBOutlet UILabel *phone;
@property (weak, nonatomic) IBOutlet UILabel *doctorNumber;
@property (weak, nonatomic) IBOutlet UIButton *expandBtn;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *expandViewBottom;


@property (nonatomic,assign) MKCoordinateRegion currentRegion;
@property (nonatomic,strong) CLPlacemark *currentPlaceInfo;

@end

@implementation DoctorMapViewController

#pragma mark - Life Cycle

-(void)viewDidLoad{
    self.navigationController.navigationBar.translucent=NO;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(doUpdateLocate:) name:LOCATIONSUCCESS object:nil];
    
    [[Locator defaultLocator]startLocation];
    
    [self initMap];
    [self initRightItem];
    
    
    UIPanGestureRecognizer *panGesture=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panHandle:)];
    [self.officeInfoView addGestureRecognizer:panGesture];
    
}

#pragma mark - INIT
-(void)initMap{
    /*
     MKMapTypeStandard = 0,//标准的
     MKMapTypeSatellite,卫星地图
     */
    self.mapView.mapType = MKMapTypeStandard;
    //设置 地图显示的区域范围(地图在视图上的中心点)
    /*
     typedef struct {
     CLLocationCoordinate2D center;//经纬度
     MKCoordinateSpan span;//缩放比例(0.01--0.05)
     } MKCoordinateRegion;
     */
    self.mapView.region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(34.77274892, 113.67591140), MKCoordinateSpanMake(0.01, 0.01));
    //是否显示用户位置
    self.mapView.showsUserLocation = YES;
    
    //设置代理
    self.mapView.delegate = self;
    
    /**
     *Zoom and scroll are enabled by default.
     */
    self.mapView.scrollEnabled=YES;
    self.mapView.zoomEnabled=YES;
    /**
     *Rotate and pitch are enabled by default on Mac OS X and on iOS 7.0 and later.
     */
    self.mapView.pitchEnabled=YES;
    self.mapView.rotateEnabled=YES;
    //self.mapAnnotation=[[BaseMapAnnotation alloc] init];
    //用户位置追踪(用户位置追踪用于标记用户当前位置，此时会调用定位服务)
    self.mapView.userTrackingMode=MKUserTrackingModeFollow;
//    self.mapView.showsCompass = NO;
}

-(void)initRightItem{
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"筛选"] style:UIBarButtonItemStylePlain target:self action:@selector(doRightItem)];
    
}
#pragma mark  -Event Responde
//重新定位
- (IBAction)doLocate:(id)sender {
    [self.mapView setCenterCoordinate:_mapView.userLocation.location.coordinate zoomLevel:28 animated:YES];
    self.expandBtn.selected = YES;
}

//关闭或展开诊所信息页面
- (IBAction)doCloseInfoView:(id)sender {
    if (isCloseView) {
        [self openOrHideInfoView:NO];
    }else{
        [self openOrHideInfoView:YES];
    }
}
//进入选择医生页面
- (IBAction)chooseDoctor:(id)sender {
    
}
//进入筛选列表
-(void)doRightItem{
    
}
/**
 *  滑动手势 事件
 *
 *  @param gesture pan手势
 */
- (void)panHandle:(UIPanGestureRecognizer *)gesture
{
    static float startPoint_Y; //记录开始滑动时的 触控位置Y坐标
    float endPoint_Y;   //记录结束滑动时的 触控位置Y坐标
    static float viewPoint_Y;  //记录开始滑动时的 约束的大小
    
    switch (gesture.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            startPoint_Y = [gesture locationInView:self.view.window].y;
            viewPoint_Y  = self.expandViewBottom.constant;
            
            NSLog(@"\n\n========开始滑动");
            NSLog(@"起始点的Y坐标为：%f",startPoint_Y);
            NSLog(@"视图的起始坐标为：%f",viewPoint_Y);
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            endPoint_Y   = [gesture locationInView:self.view.window].y;
            float gPoint = -(viewPoint_Y + (endPoint_Y - startPoint_Y));
            if (gPoint>=-self.officeInfoView.frame.size.height&&gPoint<=viewPoint_Y+100) {
                self.expandViewBottom.constant=gPoint;
            }
            
            
            [gesture setTranslation:CGPointZero inView:self.view.window];
            
            NSLog(@"\n\n=========持续滑动");
            NSLog(@"视图的坐标调整后为：%f",gPoint);
            NSLog(@"滑动的的距离为： %f",endPoint_Y - startPoint_Y);
            
        }
            break;
        case UIGestureRecognizerStateCancelled:
        {
            NSLog(@"====oh NO===滑动被取消了");
            
            /*********************************************
             * 不排除有，pan事件被中断的可能，处理同stateEnded *
             *********************************************/
            
        }
        case UIGestureRecognizerStateEnded:
        {
            NSLog(@"\n\n=========结束滑动");
            
            CGRect rect = self.officeInfoView.frame;
            
            NSLog(@"view Y === %f",self.officeInfoView.frame.origin.y);
            
            CGFloat midleLine = self.view.frame.size.height-rect.size.height/2;//判断是否展开或隐藏的分界线
            if (rect.origin.y >= midleLine) //处理 隐藏view
            {
                [self openOrHideInfoView:YES];
            }
            else                    //处理 展开view
            {
                [self openOrHideInfoView:NO];
            }
            
        }
            break;
            
        default:
            break;
    }
    
}



#pragma maerk - Animation
/**
 *  展开或隐藏infoview
 *
 *  @param hide 是否隐藏
 */
-(void)openOrHideInfoView:(BOOL)hide{
    CGFloat dist=-self.officeInfoView.frame.size.height;
    if (!hide) {
        dist=0;
    }
    __weak UIButton *weakExpandBtn = self.expandBtn;
    [UIView animateWithDuration:0.3 animations:^{
        self.expandViewBottom.constant = dist;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (hide) {
            weakExpandBtn.selected = YES;
        }else{
            weakExpandBtn.selected = NO;
        }
        
        [self doLocate:nil];
    }];
    
    isCloseView=hide;

}


-(void)selectAnnotation:(NSString *)str{
    self.expandBtn.hidden =NO;
    [self resetView];
    [self openOrHideInfoView:NO];
}
-(void)unSelectAnnotation{
    self.expandBtn.hidden =YES;
    [self openOrHideInfoView:YES];
}
-(void)resetView{
}
#pragma mark - Locate

-(void)doUpdateLocate:(NSNotification *)noti{
    
    CLLocation *location = noti.object;
    
    CLLocationCoordinate2D centerCoordanate;
    centerCoordanate.latitude = [location coordinate].latitude;
    centerCoordanate.longitude = [location coordinate].longitude;
    MKCoordinateRegion currentRegion = MKCoordinateRegionMakeWithDistance(centerCoordanate, 10000, 10000);
    
    self.currentRegion = currentRegion;
    
}



#pragma mark - Abstract methods

- (NSString *)seedFileName {
    return @"notio";
    NSAssert(FALSE, @"This abstract method must be overridden!");
    return nil;
}

- (NSString *)clusterPictoName {
    return @"notio";
    NSAssert(FALSE, @"This abstract method must be overridden!");
    return nil;
}

#pragma mark - BaseMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }else{
        DoctorOfficeAnnotationView * pinView = (DoctorOfficeAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"DoctorOfficeAnnotationView"];
        if (!pinView) {
            pinView = [[DoctorOfficeAnnotationView alloc] initWithAnnotation:annotation
                                                   reuseIdentifier:@"DoctorOfficeAnnotationView"];
        }
            pinView.annotation = annotation;
   
        return pinView;
    }
    
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForClusterAnnotation:(id<MKAnnotation>)annotation {
    MKAnnotationView * pinView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"ADMapCluster"];
    if (!pinView) {
        pinView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                               reuseIdentifier:@"ADMapCluster"];
        pinView.image = [UIImage imageNamed:self.clusterPictoName];
        pinView.canShowCallout = YES;
    }
    else {
        pinView.annotation = annotation;
    }
    return pinView;
}


- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray<MKAnnotationView *> *)views{
    
    NSLog(@"add mapview:%@",views);
}

- (void)mapViewDidFinishClustering:(BaseMapView *)mapView {
    NSLog(@"Done");
}

- (NSInteger)numberOfClustersInMapView:(BaseMapView *)mapView {
    return 40;
}

- (double)clusterDiscriminationPowerForMapView:(BaseMapView *)mapView {
    return 1.8;
}

//选中或取消选择大头钉
-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
    if ([view.reuseIdentifier isEqualToString:@"DoctorOfficeAnnotationView"]) {
        [self selectAnnotation:nil];
    }else{
        [self unSelectAnnotation];
    }
    
}
-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view{
    [self unSelectAnnotation];
}

//地图移动
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
    self.locateBtn.selected = YES;
    
}
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    //第一个坐标
    CLLocation *current=[[CLLocation alloc] initWithLatitude:mapView.region.center.latitude longitude:mapView.region.center.longitude];

    // 计算距离
    CLLocationDistance meters=[mapView.userLocation.location distanceFromLocation:current];
    
    if (meters <5) {
        self.locateBtn.selected = NO;
    }
    
}

//用户定位
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    
  
    
    [[Locator defaultLocator]getAddressByLocationCoordinate:userLocation.location.coordinate Success:^(CLPlacemark *placeInfo) {
        self.currentPlaceInfo = placeInfo;
    } Error:^(NSError *error) {
        self.currentPlaceInfo = nil;
    }];
    
}

#pragma mark - Getter and Setter
-(void)setCurrentPlaceInfo:(CLPlacemark *)currentPlaceInfo{
    MKUserLocation *userLocation = self.mapView.userLocation;
    if (!currentPlaceInfo) {
        userLocation.title = @"当前位置";
        userLocation.subtitle = nil;
    }else{
        userLocation.title = @"当前位置";
        userLocation.subtitle = currentPlaceInfo.name;
    }
    
    _currentPlaceInfo = currentPlaceInfo;
}
@end

