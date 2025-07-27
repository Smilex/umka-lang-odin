package fractal

import umka "../../"
import "core:log"
import "base:runtime"

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

    g_umka_ctx = umka.Alloc()
    assert(g_umka_ctx != nil)

    assert(umka.Init(g_umka_ctx, "fractal.um", nil, 1024 * 1024, nil, 0, nil, false, false, warn_callback))
    rv := umka.Compile(g_umka_ctx)
    our_assert(rv)
    our_assert(umka.Run(g_umka_ctx) == 0)
}
