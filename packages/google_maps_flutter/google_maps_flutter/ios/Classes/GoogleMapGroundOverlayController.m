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

static double ToDouble(NSNumber* data) { return [FLTGoogleMapJsonConversions toDouble:data]; }

static UIImage* scaleImage(UIImage* image, NSNumber* scaleParam) {
  double scale = 1.0;
  if ([scaleParam isKindOfClass:[NSNumber class]]) {
    scale = scaleParam.doubleValue;
  }
  if (fabs(scale - 1) > 1e-3) {
    return [UIImage imageWithCGImage:[image CGImage]
                               scale:(image.scale * scale)
                         orientation:(image.imageOrientation)];
  }
  return image;
}

static UIImage* ExtractIcon(NSObject<FlutterPluginRegistrar>* registrar, NSArray* iconData) {
    UIImage* image;
    if ([iconData.firstObject isEqualToString:@"defaultMarker"]) {
        CGFloat hue = (iconData.count == 1) ? 0.0f : ToDouble(iconData[1]);
        image = [GMSMarker markerImageWithColor:[UIColor colorWithHue:hue / 360.0
                                                           saturation:1.0
                                                           brightness:0.7
                                                                alpha:1.0]];
    }
    else if ([iconData.firstObject isEqualToString:@"fromAsset"])
    {
        if (iconData.count == 2)
        {
            NSString* key = [registrar lookupKeyForAsset:iconData[1]];
            NSString* path = [[NSBundle mainBundle] pathForResource:key ofType:nil];
            image = [UIImage imageNamed:[registrar lookupKeyForAsset:iconData[1]]];
        }
        else
        {
            image = [UIImage imageNamed:[registrar lookupKeyForAsset:iconData[1]
                                                         fromPackage:iconData[2]]];
        }
    }
    else if ([iconData.firstObject isEqualToString:@"fromAssetImage"])
    {
        if (iconData.count == 3)
        {
            image = [UIImage imageNamed:[registrar lookupKeyForAsset:iconData[1]]];
            NSNumber* scaleParam = iconData[2];
            image = scaleImage(image, scaleParam);
        }
        else
        {
            NSString* error =
            [NSString stringWithFormat:@"'fromAssetImage' should have exactly 3 arguments. Got: %lu",
             (unsigned long)iconData.count];
            NSException* exception = [NSException exceptionWithName:@"InvalidBitmapDescriptor"
                                                             reason:error
                                                           userInfo:nil];
            @throw exception;
        }
    } else if ([iconData[0] isEqualToString:@"fromBytes"]) {
        if (iconData.count == 2) {
            @try {
                FlutterStandardTypedData* byteData = iconData[1];
                CGFloat screenScale = [[UIScreen mainScreen] scale];
                image = [UIImage imageWithData:[byteData data] scale:screenScale];
            } @catch (NSException* exception) {
                @throw [NSException exceptionWithName:@"InvalidByteDescriptor"
                                               reason:@"Unable to interpret bytes as a valid image."
                                             userInfo:nil];
            }
        } else {
            NSString* error = [NSString
                               stringWithFormat:@"fromBytes should have exactly one argument, the bytes. Got: %lu",
                               (unsigned long)iconData.count];
            NSException* exception = [NSException exceptionWithName:@"InvalidByteDescriptor"
                                                             reason:error
                                                           userInfo:nil];
            @throw exception;
        }
    }
    
    return image;
}




// ----- IMPLEMENTATION TO CREATE OVERLAY

@interface FLTGoogleMapGroundOverlay()
-(void)intercepOverlaywith:(NSDictionary *)data registrar:(NSObject<FlutterPluginRegistrar>*)registrar;
@end

@implementation FLTGoogleMapGroundOverlay {
    GMSGroundOverlay* _groundOverlay;
    GMSMapView* _mapView;
}


-(instancetype)initGroundOverlayWithNELocation:(CLLocationCoordinate2D)northeast SWLocation:(CLLocationCoordinate2D)southwest overlayID:(NSString *)overlayID mapView:(GMSMapView *)mapView {
    
    self = [super init];
    if (self)
    {
        _mapView = mapView;
        _overlayID = overlayID;
        
    }
    return self;
    
}


-(void)removeOverlay {
    _groundOverlay.map = nil;
}


-(void)intercepOverlaywith:(NSDictionary *)data registrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
    NSLog(@"The data we have for Overlay = %@",data);
    
    NSArray *sw = data[@"southwest"];
    NSArray *ne = data[@"northeast"];
    NSArray *loc = data[@"location"];
    if (sw && ne)
    {
        CLLocationCoordinate2D swc = ToLocation(sw);
        CLLocationCoordinate2D nec = ToLocation(ne);
        
        CLLocationCoordinate2D location = ToLocation(loc);
        
        
        GMSCoordinateBounds *overlayBounds = [[GMSCoordinateBounds alloc]initWithCoordinate:swc coordinate:nec];
        // Choose the midpoint of the coordinate to focus the camera on.
        CLLocationCoordinate2D anchor = GMSGeometryInterpolate(swc, nec, 1.0);

        NSArray* icon = data[@"bitmap"];
        UIImage* image;
        if (icon)
        {
            image = ExtractIcon(registrar, icon);
        }
        
        _groundOverlay = [GMSGroundOverlay groundOverlayWithBounds:overlayBounds icon:image];
        _groundOverlay.position = location;
        _groundOverlay.map = _mapView;

    }
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
      [goverlay intercepOverlaywith:overlay registrar:_registrar];
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
  return overlay[@"groundOverlayId"];
}

@end

