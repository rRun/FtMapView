//
//  FtViewController.m
//  FtMapView
//
//  Created by hexy on 08/22/2016.
//  Copyright (c) 2016 hexy. All rights reserved.
//

#import "FtViewController.h"

#import "DoctorMapViewController.h"
@interface FtViewController ()<BaseClusterMapViewDelegate>
@property (nonatomic,strong) CLGeocoder *geocoder;
@property (nonatomic,strong)BaseMapAnnotation *mapAnnotation;
@end

@implementation FtViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _geocoder=[[CLGeocoder alloc]init];
    
//    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(doUpdateLocate:) name:LOCATIONSUCCESS object:nil];
    
//    [[Locator defaultLocator]startLocation];
    
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
    self.mapAnnotation=[[BaseMapAnnotation alloc] init];
    //用户位置追踪(用户位置追踪用于标记用户当前位置，此时会调用定位服务)
    self.mapView.userTrackingMode=MKUserTrackingModeFollow;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}
- (IBAction)doNav:(id)sender {
    [self turnByTurn];
}
#pragma mark - setLocate

-(void)setLatitude:(double)latitude Longitude:(double)longitude Scale:(float)scale{
    //设定经纬度
    CLLocationCoordinate2D theCoordinate;
    theCoordinate.latitude=latitude;
    theCoordinate.longitude=longitude;
    
    //设定显示范围
    MKCoordinateSpan theSpan;
    theSpan.latitudeDelta=scale;
    theSpan.longitudeDelta=scale;
    
    //设置地图显示的中心及范围
    MKCoordinateRegion theRegion;
    theRegion.center=theCoordinate;
    theRegion.span=theSpan;
    
    [self.mapView setRegion:theRegion];
}

#pragma mark - Locate

-(void)doUpdateLocate:(NSNotification *)noti{
    
    CLLocation *location = noti.object;
    
//    [self.mapView setCenterCoordinate:location.coordinate];
    
    
    CLLocationCoordinate2D centerCoordanate;
    centerCoordanate.latitude = [location coordinate].latitude - 0.0037;
    centerCoordanate.longitude = [location coordinate].longitude;
    MKCoordinateRegion reg = MKCoordinateRegionMakeWithDistance(centerCoordanate, 10000, 10000);
    [_mapView setRegion:reg animated:YES];
}

#pragma mark - navigation
-(void)turnByTurn{
    
    DoctorMapViewController *doctorMapVC=[[DoctorMapViewController alloc]initWithNibName:@"DoctorMapViewController" bundle:nil];
    doctorMapVC.title=@"Choose a Doctor";
    
    UINavigationController *nav=[[UINavigationController alloc]initWithRootViewController:doctorMapVC];
    
    [self presentViewController:nav animated:YES completion:nil];
    
    return;
    //根据“北京市”地理编码
    [_geocoder geocodeAddressString:@"北京市" completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *clPlacemark1=[placemarks firstObject];//获取第一个地标
        MKPlacemark *mkPlacemark1=[[MKPlacemark alloc]initWithPlacemark:clPlacemark1];
        //注意地理编码一次只能定位到一个位置，不能同时定位，所在放到第一个位置定位完成回调函数中再次定位
        [_geocoder geocodeAddressString:@"郑州市" completionHandler:^(NSArray *placemarks, NSError *error) {
            CLPlacemark *clPlacemark2=[placemarks firstObject];//获取第一个地标
            MKPlacemark *mkPlacemark2=[[MKPlacemark alloc]initWithPlacemark:clPlacemark2];
            NSDictionary *options=@{MKLaunchOptionsMapTypeKey:@(MKMapTypeStandard),MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving};
            //MKMapItem *mapItem1=[MKMapItem mapItemForCurrentLocation];//当前位置
            MKMapItem *mapItem1=[[MKMapItem alloc]initWithPlacemark:mkPlacemark1];
            MKMapItem *mapItem2=[[MKMapItem alloc]initWithPlacemark:mkPlacemark2];
            [MKMapItem openMapsWithItems:@[mapItem1,mapItem2] launchOptions:options];
            
        }];
        
    }];
}
#pragma mark - Abstract methods

- (NSString *)seedFileName {
    return @"notio";
    NSAssert(FALSE, @"This abstract method must be overridden!");
    return nil;
}

- (NSString *)pictoName {
    return @"notio";
    NSAssert(FALSE, @"This abstract method must be overridden!");
    return nil;
}

- (NSString *)clusterPictoName {
    return @"notio";
    NSAssert(FALSE, @"This abstract method must be overridden!");
    return nil;
}

#pragma mark - ADClusterMapViewDelegate
- (MKAnnotationView *)mapView:(BaseMapView *)mapView viewForClusterAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }else{
        MKAnnotationView * pinView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"ADClusterableAnnotation"];
        if (!pinView) {
            pinView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                   reuseIdentifier:@"ADClusterableAnnotation"];
            pinView.image = [UIImage imageNamed:self.pictoName];
            pinView.canShowCallout = YES;
        }
        else {
            pinView.annotation = annotation;
        }
        return pinView;
    }
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


-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
    NSLog(@"didSelectAnnotationView in %d",1);
    if ([view.reuseIdentifier isEqualToString:@"userAnnotation"]) {
        NSLog(@"mapview:%@",view);
        
    }else{
        
    }
    
}
-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view{
    NSLog(@"didDeselectAnnotationView in %d",0);
    if ([view.reuseIdentifier isEqualToString:@"userAnnotation"]) {
      
    }else{
        
    }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
     NSLog(@"123");
  
    NSLog(@"center:%f-%f\n,span:%f-%f",mapView.region.center.latitude,mapView.region.center.longitude,mapView.region.span.latitudeDelta,mapView.region.span.longitudeDelta);
}
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
     NSLog(@"321");
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    userLocation.title = @"当前定位地址";
    userLocation.subtitle = @"金牛区想潇洒和大家看好贷记卡圣诞卡圣诞卡就是贷记卡好的卡还得看啥看哈客户端卡是多快好省的空间很大啊 ";
}
@end
