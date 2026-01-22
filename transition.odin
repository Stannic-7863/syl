package syl

import "core:time"
import "core:math/ease"
import "core:fmt"

Transition :: struct {
    duration: f32,
    ease: ease.Ease,
}

Animatable_Property :: enum {
    All,
    Background_Color
}

Color_Transition :: struct {
    target: ^[4]u8,
    start: [4]u8,
    end:   [4]u8,
    start_t:   time.Tick,
    duration:  f32,
    easing:    ease.Ease,
}

Float_Transition :: struct {
    target: ^f32,
    start: f32,
    end:   f32,
    start_t:   time.Tick,
    duration:  f32,
    easing:    ease.Ease,
}

update_transitions :: proc() {
    curr_tick := time.tick_now()

    for i := len(ctx.transitions.color) - 1; i >= 0; i -= 1 { 
        t := &ctx.transitions.color[i]

        elapsed := f32(time.duration_seconds(time.tick_since(t.start_t)))
        progress := clamp(elapsed / t.duration, 0.0, 1.0)
        
        t.target^ = interpolate_color(t.start, t.end, ease.ease(t.easing, progress))
        
        if progress >= 1.0 || t.target^ == t.end {
            unordered_remove(&ctx.transitions.color, i)
        }
    }

    for i := len(ctx.transitions.float) - 1; i >= 0; i -= 1 { 
        t := &ctx.transitions.float[i]
        
        elapsed := f32(time.duration_seconds(time.tick_since(t.start_t)))
        progress := clamp(elapsed / t.duration, 0.0, 1.0)
        
        t.target^ = interpolate_float(t.start, t.end, ease.ease(t.easing, progress))
        
        if progress >= 1.0 || t.target^ == t.end {
            unordered_remove(&ctx.transitions.float, i)
        }
    }
}

animate_float:: proc(target: ^f32, end_val: f32, duration: f32, easing: ease.Ease) {
    // Clear existing transition for this pointer if it exists
    for t, i in ctx.transitions.float {
        if t.target == target {
            unordered_remove(&ctx.transitions.float, i)
            break
        }
    }

    if target^ == end_val do return

    // If duration is zero behave like immediate set (avoid division by zero in updater)
    if duration == 0 {
        target^ = end_val
        return
    }

    append(&ctx.transitions.float, Float_Transition{
        target   = target,
        start    = target^,
        end      = end_val,
        start_t  = time.tick_now(),
        duration = duration,
        easing   = easing,
    })
}

animate_color :: proc(target: ^[4]u8, end_val: [4]u8, duration: f32, easing: ease.Ease) {
    // Clear existing transition for this pointer if it exists
    for t, i in ctx.transitions.color {
        if t.target == target {
            unordered_remove(&ctx.transitions.color, i)
            break
        }
    }

    if duration == 0 {
        target^ = end_val
        return
    }

    if target^ == end_val do return

    append(&ctx.transitions.color, Color_Transition{
        target   = target,
        start    = target^,
        end      = end_val,
        start_t  = time.tick_now(),
        duration = duration,
        easing   = easing,
    })
}

interpolate_float :: proc(start, end: f32, progress: f32) -> f32 {
    return start + (end - start) * progress
}

interpolate_color :: proc(start: [4]u8, end: [4]u8, progress: f32) -> [4]u8 {
    return {
        u8(f32(start[0]) + f32(i32(end[0]) - i32(start[0])) * progress),
        u8(f32(start[1]) + f32(i32(end[1]) - i32(start[1])) * progress),
        u8(f32(start[2]) + f32(i32(end[2]) - i32(start[2])) * progress),
        u8(f32(start[3]) + f32(i32(end[3]) - i32(start[3])) * progress),
    }
}
