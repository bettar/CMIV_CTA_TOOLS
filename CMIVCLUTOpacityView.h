//
//  CMIVCLUTOpacityView.m
//  CMIV
//
//  modified from CLUTOpacityView of OsiriX.
//  
//

#import <Cocoa/Cocoa.h>
#import <Accelerate/Accelerate.h>

@interface CMIVCLUTOpacityView : NSView {
	NSColor *backgroundColor, *histogramColor, *pointsColor, *pointsBorderColor, *curveColor, *selectedPointColor, *textLabelColor;
	float histogramOpacity;
	float *volumePointer;
	int voxelCount;
	vImagePixelCount *histogram;
	int histogramSize;
	float HUmin, HUmax; // houndsfield units bounds
	NSPoint selectedPoint;
	int selectedCurveIndex;
	int pointDiameter, lineWidth, pointBorder;
	
	NSColorPanel *colorPanel;
	
	NSMutableArray *curves, *pointColors;
	
	NSMenu *contextualMenu;
	
	NSUndoManager *undoManager;
	BOOL nothingChanged;
	BOOL clutChanged;
	BOOL isInTaggedVRMode;
	
	float zoomFactor;
	float zoomFixedPoint;
	
	IBOutlet NSWindow *chooseNameAndSaveWindow;
	IBOutlet NSTextField *clutSavedName;
	
	IBOutlet NSView *vrView;
	//CMIVVRcontroller *vrController;
	NSObject* vrController;
	BOOL vrViewLowResolution;
	BOOL didResizeVRVIew;
	
	float mousePositionX;
	
	NSRect drawingRect, sideBarRect;
	NSRect addCurveButtonRect, removeSelectedCurveButtonRect, saveButtonRect;
	BOOL isAddCurveButtonHighlighted, isRemoveSelectedCurveButtonHighlighted, isSaveButtonHighlighted;
	
	NSPoint mouseDraggingStartPoint;
	BOOL updateView, setCLUTtoVRView;
}

- (void)cleanup;
- (void)createContextualMenu;

#pragma mark - Histogram
- (void)setVolumePointer:(float*)ptr width:(int)width height:(int)height numberOfSlices:(int)n;
- (void)setHUmin:(float)min HUmax:(float)max;
- (void)computeHistogram;
- (void)drawHistogramInRect:(NSRect)rect;

#pragma mark - Curves
- (void)newCurve;
- (void)fillCurvesInRect:(NSRect)rect;
- (void)drawCurvesInRect:(NSRect)rect;
- (void)addCurveAtindex:(int)curveIndex withPoints:(NSArray*)pointsArray colors:(NSArray*)colorsArray;
- (void)deleteCurveAtIndex:(int)i;
- (void)sendToBackCurveAtIndex:(int)i;
- (void)sendToFrontCurveAtIndex:(int)i;
- (int)selectedCurveIndex;
- (void)selectCurveAtIndex:(int)i;
- (void)setColor:(NSColor*)color forCurveAtIndex:(int)curveIndex;
- (void)setColors:(NSArray*)colors forCurveAtIndex:(int)curveIndex;

- (void)setCurves:(NSMutableArray*)newCurves;
- (void)setPointColors:(NSMutableArray*)newPointColors;

#pragma mark - Coordinate to NSView Transform
- (NSAffineTransform*)transform;

#pragma mark - Global draw method
- (void)updateView;

#pragma mark - Points selection
- (BOOL)selectPointAtPosition:(NSPoint)position;
- (void)unselectPoints;
- (BOOL)isAnyPointSelected;
- (void)changePointColor:(NSNotification *)notification;
- (void)setColor:(NSColor*)color forPointAtIndex:(int)pointIndex inCurveAtIndex:(int)curveIndex;
- (NSPoint)legalizePoint:(NSPoint)point inCurve:(NSArray*)aCurve atIndex:(int)j;
- (void)drawPointLabelAtPosition:(NSPoint)pt;
- (void)addPoint:(NSPoint)point atIndex:(int)pointIndex inCurveAtIndex:(int)curveIndex withColor:(NSColor *)color;
- (void)removePointAtIndex:(int)ip inCurveAtIndex:(int)ic;
- (void)replacePointAtIndex:(int)ip inCurveAtIndex:(int)ic withPoint:(NSPoint)point;

#pragma mark - Control Point
- (NSPoint)controlPointForCurveAtIndex:(int)i;
- (BOOL)selectControlPointAtPosition:(NSPoint)position;

#pragma mark - Lines selection
- (BOOL)clickOnLineAtPosition:(NSPoint)position;

#pragma mark - GUI
- (IBAction)computeHistogram:(id)sender;
- (IBAction)setHistogramOpacity:(id)sender;
- (IBAction)newCurve:(id)sender;
- (IBAction)setLineWidth:(id)sender;
- (IBAction)setPointDiameter:(id)sender;
- (void)niceDisplay;
- (IBAction)niceDisplay:(id)sender;
- (IBAction)sendToBack:(id)sender;
- (IBAction)setZoomFator:(id)sender;
- (IBAction)scroll:(id)sender;
- (void)setCursorLabelWithText:(NSString*)text;
- (IBAction)removeAllCurves:(id)sender;
- (void)addCurveIfNeeded;

#pragma mark - Custom GUI
- (void)drawSideBar:(NSRect)rect;
- (void)drawAddCurveButton:(NSRect)rect;
- (void)drawRemoveSelectedCurveButton:(NSRect)rect;
- (void)drawSaveButton:(NSRect)rect;
- (BOOL)clickInSideBarAtPosition:(NSPoint)position;
- (BOOL)clickInAddCurveButtonAtPosition:(NSPoint)position;
- (BOOL)clickInRemoveSelectedCurveButtonAtPosition:(NSPoint)position;
- (BOOL)clickInSaveButtonAtPosition:(NSPoint)position;
- (void)simplifyHistogram;
- (void)setClutChanged;

#pragma mark - Copy / Paste
- (IBAction)copy:(id)sender;
- (IBAction)paste:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)cut:(id)sender;
- (IBAction)undo:(id)sender;
- (IBAction)redo:(id)sender;

#pragma mark - Saving (as plist)
- (void)chooseNameAndSave:(id)sender;
- (IBAction)save:(id)sender;
- (void)saveWithName:(NSString*)name;
+ (NSDictionary*)presetFromFileWithName:(NSString*)name;
- (void)loadFromFileWithName:(NSString*)name;

#pragma mark conversion to plist-compatible types
- (NSArray*)convertPointColorsForPlist;
- (NSArray*)convertCurvesForPlist;
- (NSDictionary*)convertColorToDict:(NSColor*)color;
- (NSDictionary*)convertPointToDict:(NSPoint)point;

#pragma mark conversion from plist
+ (NSMutableArray*)convertPointColorsFromPlist:(NSArray*)plistPointColor;
+ (NSMutableArray*)convertCurvesFromPlist:(NSArray*)plistCurves;
- (NSMutableArray *) curves;
- (NSMutableArray *) pointColors;

#pragma mark - Connection to VRView
- (void)setCLUTtoVRView;
- (void)setCLUTtoVRView:(BOOL)lowRes;
- (void)setWL:(float)wl ww:(float)ww;

#pragma mark - Cursor
- (void)setCursorLabelWithText:(NSString*)text;
-(void)setVRController:(NSObject*)controller;
- (void)newTrapezoidCurve;

@end
