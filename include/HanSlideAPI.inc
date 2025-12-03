#if defined _Slide_INC_
    #endinput
#endif
#define _Slide_INC_

/**
 * 给予玩家滑铲
 *
 * @param client        玩家
 */
native void Han_SetPlayerSlide(int client);

/**
 * 滑铲开始广播
 * @param client     玩家索引
 */
forward void Han_SlideOnStart(int client);

/**
 * 滑铲结束广播
 * @param client     玩家索引
 */
forward void Han_SlideOnEnd(int client);

/**
 * 正在滑铲状态中
 * @param client     玩家索引
 */

native bool Han_IsSliding(int client);

