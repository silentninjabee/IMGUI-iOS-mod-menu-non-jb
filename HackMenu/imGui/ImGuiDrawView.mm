
#import "ImGuiDrawView.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Foundation/Foundation.h>
#include "imgui.h"
#include "imgui_impl_metal.h"
#import <Foundation/Foundation.h>

#define kWidth  [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height

@interface ImGuiDrawView () <MTKViewDelegate>

@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;

@end


@implementation ImGuiDrawView
static bool MenDeal = true;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.mtkView.device = self.device;
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    self.mtkView.clipsToBounds = YES;
    
    
    }


- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    NSLog(@"initWithNibName");
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [_device newCommandQueue];
    
    if (!self.device) abort();
    
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    
    ImGui::StyleColorsDark();
    
    NSString *FontPath = @"/System/Library/Fonts/LanguageSupport/PingFang.ttc";
    io.Fonts->AddFontFromFileTTF(FontPath.UTF8String, 40.f,NULL,io.Fonts->GetGlyphRangesChineseFull());
    
    ImGui_ImplMetal_Init(_device);
    
    return self;
}

+ (void)showChange:(BOOL)open
{
    MenDeal = open;
}

- (MTKView *)mtkView
{
    
    return (MTKView *)self.view;
}

- (void)loadView
{
    NSLog(@"loadView");
    CGFloat w = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width;
    CGFloat h = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height;
    self.view = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
}




#pragma mark - 互动
//What this function does is convert iOS touch events into ImGui input so that you can handle touch events in ImGui. 
//In this function, we first obtain any touch point in the touch event and convert its position to the coordinate system in ImGui so that ImGui can handle it correctly.
- (void)updateIOWithTouchEvent:(UIEvent *)event
{
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);
    
    
    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches)
    {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled)
        {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
    
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

#pragma mark - MTKViewDelegate
//Declare default switches and states
static bool 射线 = false;
static bool 方框 = false;
static bool 技能 = false;
static bool 血条 = false;
static bool 野怪 = false;
static bool 透视总开关 = false;
static bool 倒计时 = false;
static int 滑条值;
ImVec4 射线颜色 = ImVec4(1.0f, 0.0f, 0.0f, 1.0f); // 初始颜色为红色

- (void)drawInMTKView:(MTKView*)view
{
    
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;
    
    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 60);
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    if (MenDeal == true) {
        //When the menu is displayed, the interaction is YES and can be clicked.
        [self.view setUserInteractionEnabled:YES];
    } else{
        [self.view setUserInteractionEnabled:NO];
    }
    
    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil)
    {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"ImGui Jane"];
        
        ImGui_ImplMetal_NewFrame(renderPassDescriptor);
        ImGui::NewFrame();
        
        ImFont* font = ImGui::GetFont();
        font->Scale = 16.f / font->FontSize;
        
        CGFloat x = (([UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width) - 360) / 2;
        CGFloat y = (([UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height) - 320) / 2;
        
        ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_FirstUseEver);
        ImGui::SetNextWindowSize(ImVec2(360, 320), ImGuiCond_FirstUseEver);
        //MenDeal is global state for display and draw main imgui window
        if (MenDeal == true){
            
            ImGui::Begin("ImGui on iOS", &MenDeal);
            
            //Tab example=============
            ImGui::BeginTabBar("MyTabBar");
            
            ImGui::TableNextColumn();
            if (ImGui::BeginTabItem("Common")) 
            {
                // 在这里添加第一个选项卡的内容
                ImGui::Checkbox("hp bar", &血条);
                ImGui::EndTabItem(); // 结束第一个选项卡
            }
            ImGui::TableNextColumn();
            if (ImGui::BeginTabItem("高级功能")) // 开始第二个选项卡
            {
                // 在这里添加第二个选项卡的内容
                ImGui::Checkbox("倒计时", &倒计时);
                ImGui::EndTabItem(); // 结束第二个选项卡
            }
            
            ImGui::EndTabBar(); // 结束选项卡栏
            
            //二级菜单例子==========
            if (ImGui::CollapsingHeader("一个二级菜单"))
            {
                //初始化一个
                if (ImGui::BeginTable("This table has 3 columns", 2))
                {
                    ImGui::TableNextColumn();
                    ImGui::Checkbox("人物射线", &射线);
                    //color selection
                    ImGui::TableNextColumn();
                    ImGui::ColorEdit4("颜色", (float*) &射线颜色);
                    
                    
                    ImGui::TableNextColumn();
                    ImGui::Checkbox("人物方框", &方框);
                    
                    ImGui::EndTable();
                }
                
            }
            
            //single button examples===========
            ImGui::Checkbox("透视总开关", &透视总开关);
            
    //single button examples===========
            ImGui::Checkbox("My Switch", &透视总开关);
            
            //slider int
            
            ImGui::SliderInt("滑条1", &滑条值, 0, 300);
            
            //文字例子=====
            ImGui::Text("%.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);
            
            //颜色选择例子
            
            ImGui::ColorEdit4("Ray Color", (float*) &射线颜色);
            //结束菜单
            ImGui::End();
            
        }
        ImDrawList* draw_list = ImGui::GetForegroundDrawList();
        
        //add line to player
        if (射线) {
            draw_list->AddLine(ImVec2(kWidth/2, 30), ImVec2(300, 300), ImColor(射线颜色));
        }
        //add bounding box
        if (方框) {
            draw_list->AddRectFilled(ImVec2(100, 100), ImVec2(50, 20), 0xffffffff);
        }
        if (倒计时) {
            draw_list->AddText(ImGui::GetFont(), 15, ImVec2(100, 400), 0xffffffff, "555");
        }
        
        // 血条
        if (血条) {
            draw_list->AddCircle(ImVec2(kWidth/2, kHeight/2), 60, 0xFF6666FF);
        }
        
        
        ImGui::Render();
        ImDrawData* draw_data = ImGui::GetDrawData();
        ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);
        
        [renderEncoder popDebugGroup];
        [renderEncoder endEncoding];
        [commandBuffer presentDrawable:view.currentDrawable];
        
    }
    [commandBuffer commit];
}

@end

