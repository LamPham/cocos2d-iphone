/**
*	@see CCTransformTexture.h for full info
**/

#import "CCTransformTexture.h"

// uniform names
#define kCCUniformTMatrix_s			  "CC_TMatrix"

@implementation CCTransformTexture
@dynamic textureRotation, textureRotationX, textureRotationY;
@dynamic textureScale, textureScaleX, textureScaleY;
@dynamic textureAnchorPoint, texturePosition;
@dynamic textureParams;

// overriding CCSprite's designated initializer
-(id) initWithTexture:(CCTexture2D*)texture rect:(CGRect)rect rotated:(BOOL)rotated
{
	if((self = [super initWithTexture:texture rect:rect rotated:rotated] )) {
		[self setTextureScale:1.f];
		[self setTextureRotation:0];
		[self setTextureAnchorPoint:ccp(0.5f, 0.5f)];
		[self setTexturePosition:CGPointZero];
		[self setTextureParams:(ccTexParams){GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT}];
		[self loadShader];
	}
	return self;
}

/**
 *	Load our own specific shader that supports texture transformations
 */
-(void) loadShader
{
	CCGLProgram *p = [[CCGLProgram alloc] initWithVertexShaderByteArray:ccPositionTextureColor2_vert
																							fragmentShaderByteArray:ccPositionTextureColor_frag];
	
	[p addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];
	[p addAttribute:kCCAttributeNameColor index:kCCVertexAttrib_Color];
	[p addAttribute:kCCAttributeNameTexCoord index:kCCVertexAttrib_TexCoords];
	
	[p link];
	[p updateUniforms];
	
	uniformTMatrix_ = glGetUniformLocation( p->program_, kCCUniformTMatrix_s);
	
	self.shaderProgram = p;
	
	[p release];
}

/**
 *	We now transform our texture during a node to parent transform not sure the
 *	appropriate area to do texture transforms. This seems ok.
 */
- (CGAffineTransform) nodeToParentTransform
{
	[self textureTransform];
	return [super nodeToParentTransform];
}

/**
 *	I couldn't figure a nice way to reuse CCSprite logic since I had to cherry pick
 *	certain statements of logic and sprinkle in my own lines of code throughout the draw
 */
- (void) draw
{
	CC_PROFILER_START_CATEGORY(kCCProfilerCategorySprite, @"CCTextureTrasnform - draw");
	
	NSAssert(!batchNode_, @"If CCSprite is being rendered by CCSpriteBatchNode, CCSprite#draw SHOULD NOT be called");
	
	CC_NODE_DRAW_SETUP();
	
	ccGLBlendFunc( blendFunc_.src, blendFunc_.dst );
	
	ccGLBindTexture2D( [texture_ name] );
	
	//	OUR LOGIC STARTS HERE
	//	Extra logic which passes the uniform texture matrix into our shaders
	[self.shaderProgram setUniformLocation:uniformTMatrix_ withMatrix4fv:&TMat_ count:1];
	//	Special teture parameters specific for the texture transform so we don't override
	//	the params of other sprites that use the same texture
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, texTransformCache_.params.minFilter );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, texTransformCache_.params.magFilter );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, texTransformCache_.params.wrapS );
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, texTransformCache_.params.wrapT );
	//	OUR LOGIC ENDS HERE
	
	//
	// Attributes
	//
	
	ccGLEnableVertexAttribs( kCCVertexAttribFlag_PosColorTex );
	
#define kQuadSize sizeof(quad_.bl)
	long offset = (long)&quad_;
	
	// vertex
	NSInteger diff = offsetof( ccV3F_C4B_T2F, vertices);
	glVertexAttribPointer(kCCVertexAttrib_Position, 3, GL_FLOAT, GL_FALSE, kQuadSize, (void*) (offset + diff));
	
	// texCoods
	diff = offsetof( ccV3F_C4B_T2F, texCoords);
	glVertexAttribPointer(kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, kQuadSize, (void*)(offset + diff));
	
	// color
	diff = offsetof( ccV3F_C4B_T2F, colors);
	glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, kQuadSize, (void*)(offset + diff));
	
	
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	CHECK_GL_ERROR_DEBUG();
	
	
#if CC_SPRITE_DEBUG_DRAW == 1
	// draw bounding box
	CGPoint vertices[4]={
		ccp(quad_.tl.vertices.x,quad_.tl.vertices.y),
		ccp(quad_.bl.vertices.x,quad_.bl.vertices.y),
		ccp(quad_.br.vertices.x,quad_.br.vertices.y),
		ccp(quad_.tr.vertices.x,quad_.tr.vertices.y),
	};
	ccDrawPoly(vertices, 4, YES);
#elif CC_SPRITE_DEBUG_DRAW == 2
	// draw texture box
	CGSize s = self.textureRect.size;
	CGPoint offsetPix = self.offsetPosition;
	CGPoint vertices[4] = {
		ccp(offsetPix.x,offsetPix.y), ccp(offsetPix.x+s.width,offsetPix.y),
		ccp(offsetPix.x+s.width,offsetPix.y+s.height), ccp(offsetPix.x,offsetPix.y+s.height)
	};
	ccDrawPoly(vertices, 4, YES);
#endif // CC_SPRITE_DEBUG_DRAW
	
	CC_INCREMENT_GL_DRAWS(1);
	
	CC_PROFILER_STOP_CATEGORY(kCCProfilerCategorySprite, @"CCTransformTexture - draw");
	
}

/**
 *	We compute the texture affine matrix right here. So instead of glTranslate, glScale, glRotate we just
 *	manually create the matrix
 */
- (void) textureTransform
{
	if ( texTransformCache_.isDirty ) {
		
		float aX = texTransformCache_.anchorPoint.x * texture_.maxS;
		float aY = texTransformCache_.anchorPoint.y * texture_.maxT;
		
		float x = texTransformCache_.position.x + aX;
		float y = texTransformCache_.position.y + aY;
		
		float cx = 1, sx = 0, cy = 1, sy = 0;
		if( texTransformCache_.rotation.x || texTransformCache_.rotation.y ) {
			float radiansX = -CC_DEGREES_TO_RADIANS(texTransformCache_.rotation.x);
			float radiansY = -CC_DEGREES_TO_RADIANS(texTransformCache_.rotation.y);
			cx = cosf(radiansX); sx = sinf(radiansX);
			cy = cosf(radiansY); sy = sinf(radiansY);
		}
		
		if(!CGPointEqualToPoint(texTransformCache_.anchorPoint, CGPointZero) ) {
			x += cy * -aX * texTransformCache_.scale.x + -sx * -aY * texTransformCache_.scale.y;
			y += sy * -aX * texTransformCache_.scale.x +  cx * -aY * texTransformCache_.scale.y;
		}
		TMat_[2] = TMat_[3] = TMat_[6] = TMat_[7] = TMat_[8] = TMat_[9] = TMat_[11] = TMat_[14] = 0.0f;
		TMat_[10] = TMat_[15] = 1.0f;
		TMat_[0] = cy * texTransformCache_.scale.x; TMat_[4] = -sx * texTransformCache_.scale.y; TMat_[12] = x;
		TMat_[1] = sy * texTransformCache_.scale.x; TMat_[5] = cx * texTransformCache_.scale.y; TMat_[13] = y;
		texTransformCache_.isDirty = NO;
	}
}

-(float) textureRotation
{
	NSAssert( texTransformCache_.rotation.x == texTransformCache_.rotation.y, @"CCTextureTransform#rotation. RotationX != RotationY. Don't know which one to return");
	return texTransformCache_.rotation.x;
}

-(float) textureRotationX
{
	return texTransformCache_.rotation.x;
}

-(float) textureRotationY
{
	return texTransformCache_.rotation.y;
}

-(float) textureScale
{
	NSAssert( texTransformCache_.scale.x == texTransformCache_.scale.y, @"CCTextureTransform#scale. x != y. Don't know which one to return");
	return texTransformCache_.scale.x;
}

-(float) textureScaleX
{
	return texTransformCache_.scale.x;
}

-(float) textureScaleY
{
	return texTransformCache_.scale.y;
}

-(CGPoint) textureAnchorPoint
{
	return texTransformCache_.anchorPoint;
}

-(CGPoint) texturePosition
{
	return texTransformCache_.position;
}

-(ccTexParams) textureParams
{
	return texTransformCache_.params;
}

-(void) setTextureRotation: (float)newRotation
{
	texTransformCache_.rotation.x = texTransformCache_.rotation.y = newRotation;
	texTransformCache_.isDirty = YES;
}

-(void) setTextureRotationX: (float)newX
{
	texTransformCache_.rotation.x = newX;
	texTransformCache_.isDirty = YES;
}

-(void) setTextureRotationY: (float)newY
{
	texTransformCache_.rotation.y = newY;
	texTransformCache_.isDirty = YES;
}
	 
-(void) setTextureScale: (float)newScale
{
	texTransformCache_.scale.x = texTransformCache_.scale.y = newScale;
	texTransformCache_.isDirty = YES;
}
	 
-(void) setTextureScaleX: (float)newScaleX
{
	texTransformCache_.scale.x = newScaleX;
	texTransformCache_.isDirty = YES;
}

-(void) setTextureScaleY: (float)newScaleY
{
	texTransformCache_.scale.y = newScaleY;
	texTransformCache_.isDirty = YES;
}

-(void) setTexturePosition: (CGPoint)newPosition
{
	texTransformCache_.position = newPosition;
	texTransformCache_.isDirty = YES;
}

-(void) setTextureAnchorPoint: (CGPoint)newPosition
{
	texTransformCache_.anchorPoint = newPosition;
	texTransformCache_.isDirty = YES;
}

-(void) setTextureParams:(ccTexParams)textureParams
{
	texTransformCache_.params = textureParams;
}

@end

#pragma mark -
#pragma mark TTexture Actions
#pragma mark -
@implementation CCTextureMoveTo

-(void) startWithTarget:(CCNode *)aTarget
{
	[super startWithTarget:aTarget];
	startPosition_ = [(CCTransformTexture*)target_ texturePosition];
	delta_ = ccpSub( endPosition_, startPosition_ );
}

-(void) update: (ccTime) t
{	
	[target_ setTexturePosition:ccp( (startPosition_.x + delta_.x * t ), (startPosition_.y + delta_.y * t ) )];
}

@end

@implementation CCTextureMoveBy

- (id) initWithDuration: (ccTime) t position: (CGPoint) p
{
	if( !(self=[super initWithDuration: t]) )
		return nil;
	
	delta_ = p;
	return self;
}

- (id) copyWithZone: (NSZone*) zone
{
	CCAction *copy = [[[self class] allocWithZone: zone] initWithDuration: [self duration] position: delta_];
	return copy;
}

- (void) startWithTarget:(CCNode *)aTarget
{
	CGPoint dTmp = delta_;
	[super startWithTarget:aTarget];
	delta_ = dTmp;
}

- (CCActionInterval*) reverse
{
	return [[self class] actionWithDuration: duration_ position: ccp( -delta_.x, -delta_.y)];
}

@end

@implementation CCTextureRotateTo

-(void) startWithTarget:(CCNode *)aTarget
{
	originalTarget_ = target_ = aTarget;
	elapsed_ = 0.0f;
	firstTick_ = YES;
	
  //Calculate X
	startAngleX_ = [target_ rotationX];
	
	diffAngleX_ = dstAngleX_ - startAngleX_;
	if (diffAngleX_ > 180)
		diffAngleX_ -= 360;
	if (diffAngleX_ < -180)
		diffAngleX_ += 360;
  
  //Calculate Y
	startAngleY_ = [target_ rotationY];
	if (startAngleY_ > 0)
		startAngleY_ = fmodf(startAngleY_, 360.0f);
	else
		startAngleY_ = fmodf(startAngleY_, -360.0f);
  
	diffAngleY_ = dstAngleY_ - startAngleY_;
	if (diffAngleY_ > 180)
		diffAngleY_ -= 360;
}
-(void) update: (ccTime) t
{
	[target_ setTextureRotationX:startAngleX_ + diffAngleX_ * t];
	[target_ setTextureRotationY:startAngleY_ + diffAngleY_ * t];
}
@end

@implementation CCTextureRotateBy

- (void) startWithTarget:(CCNode *)aTarget
{
	[super startWithTarget:aTarget];
	startAngleX_ = [target_ textureRotationX];
	startAngleY_ = [target_ textureRotationY];
}

- (void) update: (ccTime) t
{
	[target_ setTextureRotationX: startAngleX_ + angleX_ * t];
	[target_ setTextureRotationY: startAngleY_ + angleY_ * t];
}

- (CCActionInterval*) reverse
{
	return [[self class] actionWithDuration: duration_ angleX: -angleX_ angleY: -angleY_];
}
@end

@implementation CCTextureScaleTo

- (void) startWithTarget:(CCNode *)aTarget
{
	[super startWithTarget:aTarget];
	startScaleX_ = [target_ textureScaleX];
	startScaleY_ = [target_ textureScaleY];
	deltaX_ = endScaleX_ - startScaleX_;
	deltaY_ = endScaleY_ - startScaleY_;
}

- (void) update: (ccTime) t
{
	[target_ setTextureScaleX:(startScaleX_ + deltaX_ * t )];
	[target_ setTextureScaleY:(startScaleY_ + deltaY_ * t )];
}

@end

@implementation CCTextureScaleBy

- (void) startWithTarget:(CCNode *)aTarget
{
	[super startWithTarget:aTarget];
	deltaX_ = startScaleX_ * endScaleX_ - startScaleX_;
	deltaY_ = startScaleY_ * endScaleY_ - startScaleY_;
}

- (CCActionInterval*) reverse
{
	return [[self class] actionWithDuration: duration_ scaleX: 1/endScaleX_ scaleY:1/endScaleY_];
}
@end

/**
 *	Our new vertex shader that handles all original logic from ccPositionTextureColor_vert
 *	But it also multiplies the texCoord vertex by the texture matrix
 *
 */
const GLchar * ccPositionTextureColor2_vert = 
"\
uniform mat4 CC_TMatrix;\
attribute vec4 a_position;\
attribute vec2 a_texCoord;\
attribute vec4 a_color;\
\n\
#ifdef GL_ES \n\
varying lowp vec4 v_fragmentColor;\
varying mediump vec2 v_texCoord;\n\
#else \n\
varying vec4 v_fragmentColor;\
varying vec2 v_texCoord;\n\
#endif \n\
\n\
void main()\
{\
gl_Position = CC_MVPMatrix * a_position;\
v_fragmentColor = a_color;\
v_texCoord = vec2(CC_TMatrix * vec4(a_texCoord, 0.0, 1.0));\
}\
";
