package umka

DEBUG :: #config(UMKA_DEBUG, false)
USE_DLL :: #config(UMKA_DLL, false)

when ODIN_OS == .Windows {
    when ODIN_ARCH == .amd64 {
        when USE_DLL {
            when DEBUG { foreign import umka_clib { "umka-lang/libumka_debug.lib" } }
            else       { foreign import umka_clib { "umka-lang/libumka.lib" } }
        } else {
            when DEBUG { foreign import umka_clib { "umka-lang/libumka_static_debug.lib" } }
            else       { foreign import umka_clib { "umka-lang/libumka_static.lib" } }
        }
    } else when ODIN_ARCH == .arm64 {
    }
} else when ODIN_OS == .Darwin {
    when ODIN_ARCH == .amd64 {
    } else when ODIN_ARCH == .arm64 {
        when USE_DLL {
            when DEBUG { foreign import umka_clib { "umka-lang/libumka_debug.dylib" } }
            else       { foreign import umka_clib { "umka-lang/libumka.dylib" } }
        } else {
            when DEBUG { foreign import umka_clib { "umka-lang/libumka_static_darwin_debug.a" } }
            else       { foreign import umka_clib { "umka-lang/libumka_static_darwin.a" } }
        }
    }
} else when ODIN_OS == .Darwin {
    when ODIN_ARCH == .amd64 {
        when USE_DLL {
            when DEBUG { foreign import umka_clib { "umka-lang/libumka_debug.so" } }
            else       { foreign import umka_clib { "umka-lang/libumka.so" } }
        } else {
            when DEBUG { foreign import umka_clib { "umka-lang/libumka_static_linux_debug.a" } }
            else       { foreign import umka_clib { "umka-lang/libumka_static_linux.a" } }
        }
    } else when ODIN_ARCH == .arm64 {
    }
} else {
    #panic("This OS is currently not supported")
}

import "core:c"

@(default_calling_convention="c", link_prefix="umka")
foreign umka_clib {
    Alloc :: proc() -> Context ---
    Init :: proc(umka: Context, fileName: cstring, sourceString: cstring, stackSize: c.int, reserved: rawptr, argc: c.int, argv: [^]^c.char, fileSystemEnabled: c.bool, implLibsEnabled: c.bool, warningCallback: WarningCallback) -> c.bool ---
    Compile :: proc(umka: Context) -> c.bool ---
    Run :: proc(umka: Context) -> c.int ---
    Call :: proc(umka: Context, fn: ^FuncContext) -> c.int ---
    Free :: proc(umka: Context) ---
    GetError :: proc(umka: Context) -> ^Error ---
    Alive :: proc(umka: Context) -> c.bool ---
    Asm :: proc(umka: Context) -> [^]c.char ---
    AddModule :: proc(umka: Context, fileName: cstring, sourceString: cstring) -> c.bool ---
    AddFunc :: proc(umka: Context, name: cstring, func: ExternFunc) -> c.bool ---
    GetFunc :: proc(umka: Context, moduleName: cstring, fnName: cstring, fn: ^FuncContext) -> c.bool ---
    GetCallStack :: proc(umka: Context, depth: c.int, nameSize: c.int, offset: ^c.int, fileName: [^]c.char, fnName: [^]c.char, line: ^c.int) -> c.bool ---
    SetHook :: proc(umka: Context, event: HookEvent, hook: HookFunc) ---
    AllocData :: proc(umka: Context, size: c.int, onFree: ExternFunc) -> rawptr ---
    IncRef :: proc(umka: Context, ptr: rawptr) ---
    DecRef :: proc(umka: Context, ptr: rawptr) ---
    GetMapItem :: proc(umka: Context, collection: ^Map, key: StackSlot) -> rawptr ---
    MakeStr :: proc(umka: Context, str: cstring) -> [^]c.char ---
    GetStrLen :: proc(str: cstring) -> c.int ---
    MakeDynArray :: proc(umka: Context, array: Array, type: rawptr, len: c.int) ---
    GetDynArrayLen :: proc(array: Array) -> c.int ---
    GetVersion :: proc() -> cstring ---
    GetMemUsage :: proc(umka: Context) -> i64 ---
    MakeFuncContext :: proc(umka: Context, closureType: rawptr, entryOffset: c.int, fn: ^FuncContext) ---
    GetParam :: proc(params: ^StackSlot, index: c.int) -> ^StackSlot ---
    GetUpvalue :: proc(params: ^StackSlot) -> ^Any ---
    GetResult :: proc(params: ^StackSlot, result: ^StackSlot) -> ^StackSlot ---
    GetMetadata :: proc(umka: Context) -> rawptr ---
    SetMetadata :: proc(umka: Context, metadata: rawptr) ---
}

Context :: distinct rawptr
Array :: distinct rawptr
StackSlot :: struct #raw_union {
    intVal: i64,
    uintVal: u64,
    ptrVal: rawptr,
    realVal: f64,
    real32Val: f32,
}
FuncContext :: struct {
    entryOffset: i64,
    params: ^StackSlot,
    result: ^StackSlot,
}
HookEvent :: enum i32 {
    UMKA_HOOK_CALL,
    UMKA_HOOK_RETURN,
}
Map :: struct {
    internal1: rawptr,
    internal2: rawptr,
}
Any :: struct {
    data: rawptr,
    type: rawptr,
}
Closure :: struct {
    entryOffset: i64,
    upvalue: Any,
}
Error :: struct {
    fileName: cstring,
    fnName: cstring,
    line: c.int,
    pos: c.int,
    code: c.int,
    msg: cstring,
}

ExternFunc :: proc "c" (params: ^StackSlot, result: ^StackSlot)
HookFunc :: proc "c" (fileName: cstring, funcName: cstring, line: c.int)
WarningCallback :: proc "c" (warning: ^Error)

    /*
#define UmkaDynArray(T) struct \
{ \
    void *internal; \
    int64_t itemSize; \
    T *data; \
}

*/
