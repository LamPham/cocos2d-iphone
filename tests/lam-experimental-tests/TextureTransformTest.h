
#import "BaseAppController.h"
#import "cocos2d.h"

//CLASS INTERFACE
@interface AppController : BaseAppController
@end

// HelloWorld Layer
@class CCTransformTexture;

@interface DemoLayer: CCLayer
{
	CCTextureAtlas	*atlas;
	//	weak references for quick access
	CCTransformTexture *ttexture_;
}
-(NSString*) title;
-(NSString*) subtitle;
@end

@interface Demo1 : DemoLayer
@end

@interface Demo2 : DemoLayer
@end

@interface Demo3 : DemoLayer
@end

