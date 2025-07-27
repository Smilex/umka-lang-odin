package threedcam

import umka "../../"
import "core:log"
import "base:runtime"
import rl "vendor:raylib"

g_umka_ctx: umka.Context

our_assert :: proc(rv: bool) {
    if !rv {
        err := umka.GetError(g_umka_ctx)
        log.panicf("(%v) \"%s\" from %s, in %s at %v:%v\n", err.code, err.msg, err.fileName, err.fnName, err.line, err.code)
    }
}

warn_callback : umka.WarningCallback : proc "c" (err: ^umka.Error) {
    context = runtime.default_context()
    context.logger = log.create_console_logger()
    log.warnf("(%v) \"%s\" from %s, in %s at %v:%v\n", err.code, err.msg, err.fileName, err.fnName, err.line, err.code)
}

main :: proc() {
    context.logger = log.create_console_logger()

    umkaInitBodies, umkaDrawBodies: umka.FuncContext

    g_umka_ctx = umka.Alloc()
    assert(g_umka_ctx != nil)
    defer umka.Free(g_umka_ctx)

    assert(umka.Init(g_umka_ctx, "3dcam.um", nil, 1024 * 1024, nil, 0, nil, false, false, warn_callback))

    umka.AddFunc(g_umka_ctx, "drawPlane", rlDrawPlane)
    umka.AddFunc(g_umka_ctx, "drawCube", rlDrawCube)
    
    our_assert(umka.AddModule(g_umka_ctx, "rl.um",
        `type Vector2* = struct {x, y: real32}
         type Vector3* = struct {x, y, z: real32}
         type Color*   = struct {r, g, b, a: uint8}
         fn drawPlane*(centerPos: Vector3, size: Vector2, color: Color)
         fn drawCube*(position: Vector3, width, height, length: real, color: Color)`
    ))

    rv := umka.Compile(g_umka_ctx)
    our_assert(rv)

    umka.GetFunc(g_umka_ctx, nil, "initBodies", &umkaInitBodies)
    umka.GetFunc(g_umka_ctx, nil, "drawBodies", &umkaDrawBodies)

    screenWidth := i32(800)
    screenHeight := i32(450)

    rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - 3d camera first person")
    defer rl.CloseWindow()

    // Define the camera to look into our 3D world (position, target, up vector)
    camera: rl.Camera
    camera.position = { 4.0, 2.0, 4.0 };
    camera.target = { 0.0, 1.8, 0.0 };
    camera.up = { 0.0, 1.0, 0.0 };
    camera.fovy = 60.0;

    our_assert(umka.Call(g_umka_ctx, &umkaInitBodies) == 0)

    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        rl.UpdateCamera(&camera, .FIRST_PERSON)
        rl.BeginDrawing()
            rl.ClearBackground({ 190, 190, 255, 255 })

            rl.BeginMode3D(camera)

            status := umka.Call(g_umka_ctx, &umkaDrawBodies)
            if !umka.Alive(g_umka_ctx) {
                our_assert(status == 0)
            }

            rl.EndMode3D()

            rl.DrawRectangle( 10, 10, 220, 70, rl.Fade(rl.SKYBLUE, 0.5));
            rl.DrawRectangleLines( 10, 10, 220, 70, rl.BLUE);

            rl.DrawText("First person camera default controls:", 20, 20, 10, rl.BLACK);
            rl.DrawText("- Move with keys: W, A, S, D", 40, 40, 10, rl.DARKGRAY);
            rl.DrawText("- Mouse move to look around", 40, 60, 10, rl.DARKGRAY);


        rl.EndDrawing()
    }

}

// Umka extension functions
rlDrawPlane :: proc "c" (params: ^umka.StackSlot, result: ^umka.StackSlot) {
    centerPos := cast(^rl.Vector3)umka.GetParam(params, 0)
    size := cast(^rl.Vector2)umka.GetParam(params, 1)
    color := cast(^rl.Color)umka.GetParam(params, 2)

    rl.DrawPlane(centerPos^, size^, color^)
}


rlDrawCube :: proc "c" (params: ^umka.StackSlot, result: ^umka.StackSlot)
{
    position := cast(^rl.Vector3)umka.GetParam(params, 0)
    width := umka.GetParam(params, 1).realVal
    height := umka.GetParam(params, 2).realVal
    length := umka.GetParam(params, 3).realVal
    color := cast(^rl.Color)umka.GetParam(params, 4)

    rl.DrawCube(position^, f32(width), f32(height), f32(length), color^)
}



