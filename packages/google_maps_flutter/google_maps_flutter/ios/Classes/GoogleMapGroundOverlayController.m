//
//  GoogleMapGroundOverlayController.m
//  google_maps_flutter
//
//  Created by Aeologic on 20/09/21.
//

#import "GoogleMapGroundOverlayController.h"
#import "JsonConversions.h"


// ----- FILE METHODS
static CLLocationCoordinate2D ToLocation(NSArray* data) {
  return [FLTGoogleMapJsonConversions toLocation:data];
}





// ----- IMPLEMENTATION TO CREATE OVERLAY

@interface FLTGoogleMapGroundOverlay()
-(void)intercepOverlaywith:(NSDictionary*)data;
@end

@implementation FLTGoogleMapGroundOverlay {
    GMSGroundOverlay* _groundOverlay;
    GMSMapView* _mapView;
}


-(instancetype)initGroundOverlayWithNELocation:(CLLocationCoordinate2D)northeast SWLocation:(CLLocationCoordinate2D)southwest overlayID:(NSString *)overlayID mapView:(GMSMapView *)mapView {
    
    self = [super init];
    if (self)
    {
        _groundOverlay = [[GMSGroundOverlay alloc]init];
        _mapView = mapView;
        _overlayID = overlayID;
        
    }
    return self;
    
}


-(void)removeOverlay {
    _groundOverlay.map = nil;
}


-(void)intercepOverlaywith:(NSDictionary *)data
{
    
}

@end




// ---- THIS CLASS WILL PARSE THE OBJECT PASSED FROM FLUTTER

@implementation FLTGroundOverlayController
{
  NSMutableDictionary* _groundOverlayControllers;
  FlutterMethodChannel* _methodChannel;
  NSObject<FlutterPluginRegistrar>* _registrar;
  GMSMapView* _mapView;
}


- (instancetype)init:(FlutterMethodChannel*)methodChannel
             mapView:(GMSMapView*)mapView
           registrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  self = [super init];
  if (self) {
    _methodChannel = methodChannel;
    _mapView = mapView;
      _groundOverlayControllers = [NSMutableDictionary dictionaryWithCapacity:1];
    _registrar = registrar;
  }
  return self;
}

- (void)addGroundOverlays:(NSArray *)overlaysToAdd
{
  for (NSDictionary* overlay in overlaysToAdd)
  {
      NSString *overlayID = [FLTGroundOverlayController getOverlayId:overlay];
      CLLocationCoordinate2D NE = [FLTGroundOverlayController getNorthEast:overlay];
      CLLocationCoordinate2D SW = [FLTGroundOverlayController getSouthWest:overlay];
      
      FLTGoogleMapGroundOverlay *goverlay = [[FLTGoogleMapGroundOverlay alloc]initGroundOverlayWithNELocation:NE SWLocation:SW overlayID:overlayID mapView:_mapView];
      [goverlay intercepOverlaywith: overlay];
      _groundOverlayControllers[overlayID] = goverlay;
  }
}



// ---- CLASS METHODS

+ (CLLocationCoordinate2D)getNorthEast:(NSDictionary*)overlay
{
  NSArray* center = overlay[@"northeast"];
  return ToLocation(center);
}

+ (CLLocationCoordinate2D)getSouthWest:(NSDictionary*)overlay
{
  NSArray* center = overlay[@"southwest"];
  return ToLocation(center);
}


+ (NSString*)getOverlayId:(NSDictionary*)overlay
{
  return overlay[@"circleId"];
}

@end

