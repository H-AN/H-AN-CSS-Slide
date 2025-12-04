   
    CS起源滑铲插件附加API
    
    轻松实现滑铲功能.

    使用此API需要骨骼动画模型支持, 需要第三人称外部动画插件API支持,感谢杰西制作的滑铲骨骼动画
    
    API功能
    native void Han_SetPlayerSlide(client) 直接给予玩家滑铲
    forward Han_SlideOnStart(client) 滑铲开始时广播
    forward Han_SlideOnEnd(client) 滑铲结束时广播
    native bool Han_IsSliding(client) 检查滑铲状态
    
    API使用方法 
    1. 将编译好的smx文件放入插件文件夹
    2. 将API文件 HanSlideAPI.inc 放入 include 文件夹
    3. 使用API需要自己设置插件内 #include <HanSlideAPI>
    4. 根据API功能随意使用吧

    cvar
    sliding_enable 1 是否开启滑铲 默认1 开启 (是否开启插件本体滑铲,适用于独立插件使用,无需额外任何插件,如果要使用API在其他插件内定义 例如想要集成奔跑等差价, 请自行使用API并关闭此选项)
    sliding_slideforce 500.0 基础滑铲力 默认500,无论速度如何 基础给予500的滑铲力度 经测试 是较为合适的力
    sliding_speedscale 1.0 玩家移动速度乘倍 默认 1.0  根据玩家的移动速度增加滑铲的力,公式为 (玩家当前速度 * 值) + 基础滑铲力 玩家速度越快滑铲力越大
    sliding_maxspeed 0.0 玩家最大的滑铲力限制 默认 0.0 ,防止滑铲力度过大 设置为0.0为不限速
    sliding_airslide 0 允许玩家在空中触发滑铲 默认0 不允许 
    sliding_slidejump 1 是否开启滑铲跳 默认 1 开启, 滑铲跳是在滑铲途中按跳跃可以获得额外的跳跃高度与距离 在空中无法滑铲跳!
    sliding_slidejumpforce 500.0 滑铲跳高度, 默认500.0 经测试是一个较为合适的值 
    sliding_slidemixspeed 100.0 允许触发滑铲的最小速度, 默认 100.0, 玩家最大速度默认是 250左右 100 相当于走路速度 
    sliding_firstpersonhideweapon 1 第一人称是否隐藏武器模型,默认1 隐藏, 根据上面区分第三人称和第一人称的原理 来决定 第一人称的时候隐藏滑铲模型手上的武器,防止穿帮,第三人称的时候不隐藏
    sliding_slidesound vehicles/v8/skid_lowfriction.wav 滑铲音效填写空值则不播放

    

 插件默认按蹲下进行滑铲,速度必须高于配置最小速度(默认 : 100.0)
 使用API可以关闭此插件功能 sliding_enable 0 设置为 0 按蹲下不会滑铲
 但是可以在其他插件使用API进行滑铲逻辑制作








    
