//
//  GoogleMapGroundOverlayController.h
//  google_maps_flutter
//
//  Created by Aeologic on 20/09/21.
//

#import <UIKit/UIKit.h>

#import <Flutter/Flutter.h>
#import <GoogleMaps/GoogleMaps.h>



@interface FLTGoogleMapGroundOverlay : NSObject

@property(atomic, readonly) NSString* overlayID;

- (instancetype)initGroundOverlayWithNELocation:(CLLocationCoordinate2D)northeast
                                SWLocation:(CLLocationCoordinate2D)southwest
                              overlayID:(NSString*)overlayID
                               mapView:(GMSMapView*)mapView;

- (void)removeOverlay;



@end




@interface FLTGroundOverlayController : NSObject

- (instancetype)init:(FlutterMethodChannel*)methodChannel
             mapView:(GMSMapView*)mapView
           registrar:(NSObject<FlutterPluginRegistrar>*)registrar;

- (void)addGroundOverlays:(NSArray*)overlaysToAdd;

@end

