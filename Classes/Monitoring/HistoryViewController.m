//
//  HistoryViewController.m
//
//  Created by Jerome on 29/08/11.
//  Copyright 2010 Defitech. All rights reserved.
//

#import "HistoryViewController.h"
#import "ParametersManager.h"
#import "FLAPIBlow.h"
#import "FlowerController.h"
#import "FLAPIExercice.h"
#import "FLAPIX.h"

@implementation HistoryViewController



# pragma mark TIMERS
NSTimer *repeatingTimer;

- (void) initTimersAndListeners {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification 
                                               object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(eventFlapixStarted:)
                                                 name:FLAPIX_EVENT_START 
                                               object:nil];
    
    // Listen to FLAPIX blowEvents
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(flapixEventEndBlow:)
                                                 name:FLAPIX_EVENT_BLOW_STOP object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(flapixEventExerciceStart:)
                                                 name:FLAPIX_EVENT_EXERCICE_START object:nil];
}

- (void) startReloadTimer {
    if (! [[FlowerController currentFlapix] running]) return;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                      target:self selector:@selector(timerFireMethod:)
                                                    userInfo:nil  repeats:YES];
    repeatingTimer = timer;
    
}

- (void) stopReloadTimer {
    [repeatingTimer invalidate];
    repeatingTimer = nil;
    
}

- (void) timerFireMethod:(NSTimer*)theTimer {
    if (! [[FlowerController currentFlapix] running]) [self stopReloadTimer];
    [graph reloadData];
}



- (void)applicationWillResignActive:(NSNotification *)notification {
    NSLog(@"HISTORY VIEW resign active");
    [self stopReloadTimer];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    NSLog(@"HISTORY VIEW become active");
    [self startReloadTimer];
}

- (void)eventFlapixStarted:(NSNotification *)notification {
    NSLog(@"HISTORY VIEW flapix started");
    [self startReloadTimer];
}


# pragma mark VIEWS LOADING

- (void)loadView {
	// Alloc & Init Main View
	UIView *tmpView = [ [ UIView alloc ] initWithFrame:CGRectMake(40.0, 420.0, 280.0, 40.0) ];
	[ tmpView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight ];
	[ tmpView setBackgroundColor:[ UIColor blackColor ] ];
	[ self setView:[ tmpView autorelease ] ];
    
    // Add Touch
    UITapGestureRecognizer *singleFingerTap = 
    [[UITapGestureRecognizer alloc] initWithTarget:self 
                                            action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:singleFingerTap];
    [singleFingerTap release];

    
	
	// Alloc Graph View
	graphView = [ [ CPGraphHostingView alloc ] initWithFrame:CGRectMake(0.0, 0.0, 230.0, 40.0) ];
	[ self.view addSubview:[ graphView autorelease ] ];
    
    // Alloc Label View
    labelPercent = [ [ UILabel alloc ] initWithFrame:CGRectMake(230.0, 0.0, 50.0, 12.0) ];
    [labelPercent setBackgroundColor:[UIColor blackColor]];
    [labelPercent setTextColor:[UIColor whiteColor]];
    [labelPercent setFont:[UIFont systemFontOfSize:8.0]];
    [labelPercent setText:@"-"];
    
    labelFrequency = [ [ UILabel alloc ] initWithFrame:CGRectMake(230.0, 14.0, 50.0, 12.0) ];
    [labelFrequency setBackgroundColor:[UIColor blackColor]];
    [labelFrequency setTextColor:[UIColor whiteColor]];
    [labelFrequency setFont:[UIFont systemFontOfSize:8.0]];
    [labelFrequency setText:@"-"];
    
    
    [ self.view addSubview:labelPercent ];
    [ self.view addSubview:labelFrequency ];
    
    historyDuration = 2; // 2 minutes
    graphPadding = 2; // 2 pixels
    
    history = [[BlowHistory alloc] initWithDuration:historyDuration delegate:self];
    
    higherBar = 0;
}


- (void)viewDidLoad {
    
    [ super viewDidLoad ];
	
	/*
	 *	CPXYGraph Prefs
	 */
	// Alloc CPXYGraph
	graph = [ [ CPXYGraph alloc ] initWithFrame: self.view.bounds ];
	// Link between the view and the Layer
	graphView.hostedGraph = graph;
	// Init Padding to 2
	graph.paddingLeft = graphPadding;
	graph.paddingTop = graphPadding;
	graph.paddingRight = graphPadding;
	graph.paddingBottom = graphPadding;
	
	/*
	 *	Graph Prefs
	 */
	// Default X & Y Range for Plot Space
	plotSpace = (CPXYPlotSpace *)graph.defaultPlotSpace;
	// Set X Range from -45 minutes to now
	plotSpace.xRange = [CPPlotRange
                        plotRangeWithLocation:CPDecimalFromDouble(-(historyDuration * 60))
                        length:CPDecimalFromDouble(historyDuration * 60 + 1)];
	// Set Y Range from 0 to 4 secondes
	plotSpace.yRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromDouble(0) length:CPDecimalFromDouble(higherBar)];
    
	/*
	 *	Axis Prefs
	 */
	// Line Style
	CPLineStyle *lineStyle = [CPLineStyle lineStyle];
	lineStyle.lineColor = [CPColor whiteColor];
	lineStyle.lineWidth = 1.0f;
	
	// Axis X Prefs
	CPXYAxisSet *axisSet = (CPXYAxisSet *)graph.axisSet;
	// Set axis line style
	axisSet.xAxis.axisLineStyle = lineStyle;
    axisSet.xAxis.labelExclusionRanges = [NSArray arrayWithObjects:
                                          [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(-200) 
                                                                      length:CPDecimalFromFloat(250)], nil];
    
	// Axis Y Prefs (same things)
	axisSet.yAxis.axisLineStyle = lineStyle;
    axisSet.yAxis.labelExclusionRanges = [NSArray arrayWithObjects:
                                          [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(-10) 
                                                                      length:CPDecimalFromFloat(20)], nil];
	
	/*
	 *	PLOTS
	 */
	// isGood plot
	CPScatterPlot *goodPlot = [[[CPScatterPlot alloc]initWithFrame:self.view.bounds] autorelease];
    goodPlot.identifier = @"isGood";
	goodPlot.dataLineStyle.lineWidth = 1.0f;
	goodPlot.dataLineStyle.lineColor = [CPColor blackColor];
	goodPlot.dataSource = self;
	[ graph addPlot:goodPlot];
    
    // blow duration plot
    CPBarPlot* blowPlot = [[[CPBarPlot alloc] initWithFrame:self.view.bounds] autorelease];
    blowPlot.identifier = @"blow";
    blowPlot.dataSource = self;
    blowPlot.barWidth = 5;
    blowPlot.barOffset = 0;  
    blowPlot.fill = [[[CPFill alloc] initWithColor:[CPColor redColor]] autorelease];
    [ graph addPlot:blowPlot ];
    
    // in range duration
    CPBarPlot* inRangePlot = [[[CPBarPlot alloc] initWithFrame:self.view.bounds] autorelease];
    inRangePlot.identifier = @"inRange";
    inRangePlot.dataSource = self;
    inRangePlot.barWidth = 5;
    inRangePlot.barOffset = 0;
    inRangePlot.fill = [[[CPFill alloc] initWithColor:[CPColor greenColor]] autorelease];
    [ graph addPlot:inRangePlot ];
    
    
    [self initTimersAndListeners];
	
}




# pragma mark graph


- (NSUInteger)numberOfRecordsForPlot:(CPPlot *)plot {
    
    return [[history getHistoryArray] count];
    
}

- (NSNumber *)numberForPlot:(CPPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
	
    FLAPIBlow* current = [[history getHistoryArray] objectAtIndex:index];
    
//    NSLog(@"timestamp = %f", current.timestamp);
//    NSLog(@"in_range_duration = %f", current.in_range_duration);
//    NSLog(@"duration = %f", current.duration);
//    NSLog(@"goal = %@", (current.goal ? @"YES" : @"NO"));
    
    switch ( fieldEnum ) {
        case CPScatterPlotFieldY:
            if (current.goal)
                return [ NSNumber numberWithDouble:(higherBar + higherBar/10) ];
            break;
        case CPBarPlotFieldBarLength:
            if (plot.identifier == @"inRange")
                return [ NSNumber numberWithDouble:current.in_range_duration ];
                
            else if (plot.identifier == @"blow")
                return [ NSNumber numberWithDouble:current.duration ];
            
            break;
        default:
            return [ NSNumber numberWithDouble:current.timestamp - CFAbsoluteTimeGetCurrent() ];
            break;
    }
	
	// Return a default value, shouldn't be returned
	return nil;
	
}

-(CPPlotSymbol *)symbolForScatterPlot:(CPScatterPlot *)plot recordIndex:(NSUInteger)index {
    CPPlotSymbol *symbol = [[[CPPlotSymbol alloc] init] autorelease];
    symbol.symbolType = CPPlotSymbolTypeStar;
    symbol.size = CGSizeMake(10.0, 10.0);
    symbol.fill = [CPFill fillWithColor:[CPColor whiteColor]];
    return symbol;
}


-(void) historyChange:(id*) history_id {
    //    NSLog(@"History change %i",[[(BlowHistory*)history_id getHistoryArray] count]);
    //redraw the graph
    [graph reloadData];
    
    // update labels
}

- (void)flapixEventEndBlow:(NSNotification *)notification {
	FLAPIBlow* blow = (FLAPIBlow*)[notification object];
    int p = (int)([[[FlowerController currentFlapix] currentExercice] percent_done]*100);
    [labelPercent setText:[NSString stringWithFormat:@"%i %%",p]];
    [labelFrequency setText:[NSString stringWithFormat:@"%i Hz",(int)blow.medianFrequency]];
    
    //Resize Y axis if needed
    if (blow.duration > higherBar) {
        higherBar = blow.duration;
        plotSpace.yRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromDouble(0) length:CPDecimalFromDouble(higherBar + higherBar/5)];
    }
}

- (void)flapixEventExerciceStart:(NSNotification *)notification {
    higherBar = 0;
}

//The event handling method
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
    [FlowerController showNav];
     NSLog(@"Graph Touched");
    //Do stuff here...
   
}

- (void)dealloc {
    [labelPercent release];
	[history release];
    [graph release];
    [super dealloc];
	
}

@end