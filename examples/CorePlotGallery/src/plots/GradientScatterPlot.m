//
//  GradientScatterPlot.m
//  CorePlotGallery
//
//  Created by Jeff Buck on 8/2/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//

#import "GradientScatterPlot.h"

@implementation GradientScatterPlot

+(void)load
{
    [super registerPlotItem:self];
}

-(id)init
{
    if ( (self = [super init]) ) {
        self.title   = @"Gradient Scatter Plot";
        self.section = kLinePlots;
    }

    return self;
}

-(void)killGraph
{
    if ( [self.graphs count] ) {
        CPTGraph *graph = [self.graphs objectAtIndex:0];

        if ( symbolTextAnnotation ) {
            [graph.plotAreaFrame.plotArea removeAnnotation:symbolTextAnnotation];
            [symbolTextAnnotation release];
            symbolTextAnnotation = nil;
        }
    }

    [super killGraph];
}

-(void)generateData
{
    if ( plotData == nil ) {
        NSMutableArray *contentArray = [NSMutableArray arrayWithCapacity:100];
        for ( NSUInteger i = 0; i < 10; i++ ) {
            id x = [NSDecimalNumber numberWithDouble:1.0 + i * 0.05];
            double yVal = 1.2 * rand() / (double)RAND_MAX + 0.5;
            yVal = MAX(0, yVal);
            id y = [NSDecimalNumber numberWithDouble:yVal];
            [contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
        }
        plotData = [contentArray retain];
    }
}

-(void)renderInLayer:(CPTGraphHostingView *)layerHostingView withTheme:(CPTTheme *)theme animated:(BOOL)animated
{
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    CGRect bounds = layerHostingView.bounds;
#else
    CGRect bounds = NSRectToCGRect(layerHostingView.bounds);
#endif

    CPTGraph *graph = [[[CPTXYGraph alloc] initWithFrame:bounds] autorelease];
    [self addGraph:graph toHostingView:layerHostingView];
    [self applyTheme:theme toGraph:graph withDefault:[CPTTheme themeNamed:kCPTSlateTheme]];

    [self setTitleDefaultsForGraph:graph withBounds:bounds];
    [self setPaddingDefaultsForGraph:graph withBounds:bounds];

    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.delegate              = self;

    // Grid line styles
    CPTMutableLineStyle *majorGridLineStyle = nil;//[CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.75;
    majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];

    CPTMutableLineStyle *minorGridLineStyle = nil;// [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 0.25;
    minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];

    // Axes
    // Label x axis with a fixed interval policy
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.majorIntervalLength         = CPTDecimalFromString(@"0.5");
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"1.0");
    x.minorTicksPerInterval       = 2;
    x.majorGridLineStyle          = majorGridLineStyle;
    x.minorGridLineStyle          = minorGridLineStyle;

//    x.title         = @"X Axis";
//    x.titleOffset   = 30.0;
//    x.titleLocation = CPTDecimalFromString(@"1.25");

    // Label y with an automatic label policy.
    CPTXYAxis *y = axisSet.yAxis;
    y.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];

//    y.labelingPolicy              = CPTAxisLabelingPolicyAutomatic;
//    y.orthogonalCoordinateDecimal = CPTDecimalFromString(@"1.0");
//    y.minorTicksPerInterval       = 2;
//    y.preferredNumberOfMajorTicks = 8;
//    y.majorGridLineStyle          = majorGridLineStyle;
//    y.minorGridLineStyle          = minorGridLineStyle;
//    y.labelOffset                 = 10.0;

//    y.title         = @"Y Axis";
//    y.titleOffset   = 30.0;
//    y.titleLocation = CPTDecimalFromString(@"1.0");

    // Create a plot that uses the data source method
    CPTScatterPlot *dataSourceLinePlot = [[[CPTScatterPlot alloc] init] autorelease];
    dataSourceLinePlot.identifier = @"Data Source Plot";
    

    CPTMutableLineStyle *lineStyle = [[dataSourceLinePlot.dataLineStyle mutableCopy] autorelease];
    lineStyle.lineWidth              = 0.0;
    lineStyle.lineColor              = nil;//[CPTColor greenColor];
    dataSourceLinePlot.interpolation = CPTScatterPlotInterpolationCurved;
    dataSourceLinePlot.dataLineStyle = lineStyle;
    dataSourceLinePlot.dataSource    = self;
    [graph addPlot:dataSourceLinePlot];

    // Put an area gradient under the plot above
    CPTColor *areaColor       = [CPTColor colorWithComponentRed:0.9 green:.1 blue:0.2 alpha:.8];
    CPTColor *endColor        = [CPTColor colorWithComponentRed:.9 green:.1 blue:0.3 alpha:.5];
    CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:endColor];
//    areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:endColor beginningPosition:0 endingPosition:1];
    areaGradient.angle = -90.0;
    CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
    dataSourceLinePlot.areaFill      = areaGradientFill;
    dataSourceLinePlot.areaBaseValue = CPTDecimalFromString(@".1");

    // Auto scale the plot space to fit the plot data
    // Extend the ranges by 30% for neatness
    [plotSpace scaleToFitPlots:[NSArray arrayWithObjects:dataSourceLinePlot, nil]];
    CPTMutablePlotRange *xRange = [[plotSpace.xRange mutableCopy] autorelease];
    CPTMutablePlotRange *yRange = [[plotSpace.yRange mutableCopy] autorelease];
    [xRange expandRangeByFactor:CPTDecimalFromDouble(1.0)];
    [yRange expandRangeByFactor:CPTDecimalFromDouble(1.3)];
    plotSpace.xRange = xRange;
    plotSpace.yRange = yRange;

    // Restrict y range to a global range
    CPTPlotRange *globalYRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0f)
                                                              length:CPTDecimalFromFloat(2.0f)];
    plotSpace.globalYRange = globalYRange;

    // Add plot symbols
    CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
    symbolLineStyle.lineColor = [CPTColor clearColor];
    CPTPlotSymbol *plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    plotSymbol.fill               = [CPTFill fillWithColor:[CPTColor colorWithCGColor:[[UIColor colorWithWhite:.9 alpha:1] CGColor]]];
    plotSymbol.lineStyle          = symbolLineStyle;
    plotSymbol.size               = CGSizeMake(7.0, 7.0);
    dataSourceLinePlot.plotSymbol = plotSymbol;

    // Set plot delegate, to know when symbols have been touched
    // We will display an annotation when a symbol is touched
    dataSourceLinePlot.delegate                        = self;
    dataSourceLinePlot.plotSymbolMarginForHitDetection = 15.0f;
}

-(void)dealloc
{
    [plotData release];
    [super dealloc];
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return [plotData count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y");
    NSNumber *num = [[plotData objectAtIndex:index] valueForKey:key];

    if ( fieldEnum == CPTScatterPlotFieldY ) {
        num = [NSNumber numberWithDouble:[num doubleValue]];
    }

    return num;
}

#pragma mark -
#pragma mark Plot Space Delegate Methods

-(CPTPlotRange *)plotSpace:(CPTPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate
{
    // Impose a limit on how far user can scroll in x
    if ( coordinate == CPTCoordinateX ) {
        CPTPlotRange *maxRange            = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-1.0f) length:CPTDecimalFromFloat(6.0f)];
        CPTMutablePlotRange *changedRange = [[newRange mutableCopy] autorelease];
        [changedRange shiftEndToFitInRange:maxRange];
        [changedRange shiftLocationToFitInRange:maxRange];
        newRange = changedRange;
    }else if ( coordinate == CPTCoordinateY ){
        newRange = ((CPTXYPlotSpace *)space).yRange;
    }
    return newRange;
}

#pragma mark -
#pragma mark CPTScatterPlot delegate method

-(void)scatterPlot:(CPTScatterPlot *)plot plotSymbolWasSelectedAtRecordIndex:(NSUInteger)index
{
    CPTGraph *graph = [self.graphs objectAtIndex:0];

    if ( symbolTextAnnotation ) {
        [graph.plotAreaFrame.plotArea removeAnnotation:symbolTextAnnotation];
        symbolTextAnnotation = nil;
    }

    // Setup a style for the annotation
    CPTMutableTextStyle *hitAnnotationTextStyle = [CPTMutableTextStyle textStyle];
    hitAnnotationTextStyle.color    = [CPTColor whiteColor];
    hitAnnotationTextStyle.fontSize = 16.0f;
    hitAnnotationTextStyle.fontName = @"Helvetica-Bold";

    // Determine point of symbol in plot coordinates
    NSNumber *x          = [[plotData objectAtIndex:index] valueForKey:@"x"];
    NSNumber *y          = [[plotData objectAtIndex:index] valueForKey:@"y"];
    NSArray *anchorPoint = [NSArray arrayWithObjects:x, y, nil];

    // Add annotation
    // First make a string for the y value
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setMaximumFractionDigits:2];
    NSString *yString = [formatter stringFromNumber:y];

    // Now add the annotation to the plot area
    CPTTextLayer *textLayer = [[[CPTTextLayer alloc] initWithText:yString style:hitAnnotationTextStyle] autorelease];
    symbolTextAnnotation              = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:graph.defaultPlotSpace anchorPlotPoint:anchorPoint];
    symbolTextAnnotation.contentLayer = textLayer;
    symbolTextAnnotation.displacement = CGPointMake(0.0f, 20.0f);
    [graph.plotAreaFrame.plotArea addAnnotation:symbolTextAnnotation];
}

@end
