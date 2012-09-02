//
//  HelloWorldLayer.m
//  PlaneWithMotionStreak
//
//  Created by Lam Pham on 12-09-01.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

#pragma mark - HelloWorldLayer


#define kPlaneRotationAction 123

// HelloWorldLayer implementation
@implementation HelloWorldLayer

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init]) ) {
		self.isTouchEnabled = YES;
		// create and initialize a Label
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"Fly you coconut... you" fontName:@"Marker Felt" fontSize:64];
		ship_ = [CCSprite spriteWithFile:@"ship.png"];
		ship_.position = ccpMult(ccpFromSize([CCDirector sharedDirector].winSize), 0.5f);
		[self addChild:ship_ z:1];
		motionStreak_ = [[CCMotionStreak streakWithFade:3.f minSeg:3 width:5 color:ccc3(135,206,235) textureFilename:@"streak.png"] retain];
		[self addChild:motionStreak_];
		motionStreak_.position = prevPt_ = curPt_ = ship_.position;

		// ask director for the window size
		CGSize size = [[CCDirector sharedDirector] winSize];
	
		// position the label on the center of the screen
		label.position =  ccp( size.width /2 , size.height - label.contentSize.height );
		
		// add the label as a child to this Layer
		[self addChild: label];
		
		[self scheduleUpdate];
		
		//
		// Leaderboards and Achievements
		//
		
		// Default font size will be 28 points.
		[CCMenuItemFont setFontSize:28];
		
		// Achievement Menu Item using blocks
		CCMenuItem *itemAchievement = [CCMenuItemFont itemWithString:@"Achievements" block:^(id sender) {
			
			
			GKAchievementViewController *achivementViewController = [[GKAchievementViewController alloc] init];
			achivementViewController.achievementDelegate = self;
			
			AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
			
			[[app navController] presentModalViewController:achivementViewController animated:YES];
			
			[achivementViewController release];
		}
									   ];

		// Leaderboard Menu Item using blocks
		CCMenuItem *itemLeaderboard = [CCMenuItemFont itemWithString:@"Leaderboard" block:^(id sender) {
			
			
			GKLeaderboardViewController *leaderboardViewController = [[GKLeaderboardViewController alloc] init];
			leaderboardViewController.leaderboardDelegate = self;
			
			AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
			
			[[app navController] presentModalViewController:leaderboardViewController animated:YES];
			
			[leaderboardViewController release];
		}
									   ];
		
		CCMenu *menu = [CCMenu menuWithItems:itemAchievement, itemLeaderboard, nil];
		
		[menu alignItemsHorizontallyWithPadding:20];
		[menu setPosition:ccp( size.width/2, 0 + 50)];
		
		// Add the menu to the layer
		[self addChild:menu];

	}
	return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

-(void)update:(ccTime)delta
{
}
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	curPt_ = [self convertTouchToNodeSpace:[touches anyObject]];
	ship_.position = curPt_;
	prevPt_ = curPt_;
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	curPt_ = [self convertTouchToNodeSpace:[touches anyObject]];
	ship_.position = curPt_;
	if (!CGPointEqualToPoint(curPt_, prevPt_)) {
		//Determine ship rotation based on user touch coordinates... for now we don't filter so the ship can
		//stutter quite a lot.
		float rotationBasedOnTouch = CC_RADIANS_TO_DEGREES( ccpAngleSigned( ccpSub(curPt_,prevPt_), ccp(1,0) ));
		ship_.rotation = rotationBasedOnTouch;
		
		//Everytime the ship position changes, we determine the new motion streak position behind the tail
		CGPoint rearPoint = ccp(ship_.position.x - ship_.contentSize.width * ship_.anchorPoint.x, ship_.position.y);
		motionStreak_.position = ccpRotateByAngle(rearPoint, ship_.position, -CC_DEGREES_TO_RADIANS (ship_.rotation) );
	}
	prevPt_ = curPt_;
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	
}

#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}
@end
