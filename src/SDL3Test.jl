module SDL3Test

sdl3_lib = "libSDL3.so"

@static if Sys.iswindows()
   sdl3_lib = "libSDL3.dll"
elseif Sys.isapple()
   sdl3_lib = "libSDL3.dylib"
else
   sdl3_lib = "libSDL3.so"
end

const SDL_Window_Ptr = Ptr{Cvoid}
const SDL_Renderer_Ptr = Ptr{Cvoid}
const SDL_Event_Ptr = Ptr{Cvoid}

const Cbool = UInt8

mutable struct SDL_FRect
    x::Cfloat
    y::Cfloat
    w::Cfloat
    h::Cfloat
end

const SDL_InitFlags = Cuint
const SDL_INIT_VIDEO::Cuint = 0x00000020

const SDL_WindowFlags = Cuint

const SDL_EventType = UInt32
const SDL_EVENT_QUIT::UInt32 = 0x100
const SDL_EVENT_KEY_DOWN::UInt32 = 0x300
const SDL_EVENT_KEY_UP::UInt32 = 0x301
const SDL_EVENT_MOUSE_MOTION::UInt32 = 1024
const SDL_EVENT_MOUSE_BUTTON_DOWN::UInt32 = 1025
const SDL_EVENT_MOUSE_BUTTON_UP::UInt32 = 1026

const SDL_Keycode = UInt32
const SDLK_RETURN = 0x0000000d
const SDLK_ESCAPE = 0x0000001b

const SDL_WindowID = UInt32
const SDL_KeyboardID = UInt32
const SDL_MouseID = UInt32
const SDL_MouseButtonFlags = UInt32
const SDL_Scancode = UInt64
const SDL_Keymod = UInt16

mutable struct SDL_KeyboardEvent 
    type::SDL_EventType
    reserved::UInt32
    timestamp::UInt64
    windowID::SDL_WindowID
    which::SDL_KeyboardID
    scancode::SDL_Scancode
    raw::UInt32
    down::Cbool
    repeat::Cbool
end

mutable struct SDL_MouseButtonEvent
    type::SDL_EventType
    reserved::UInt32
    timestamp::UInt64
    windowID::SDL_WindowID
    which::SDL_MouseID
    button::UInt8
    down::Cbool
    clicks::UInt8
    padding::UInt8
    x::Cfloat
    y::Cfloat
end

mutable struct SDL_MouseMotionEvent
    type::SDL_EventType
    reserved::UInt32
    timestamp::UInt64
    windowID::SDL_WindowID
    which::SDL_MouseID
    state::SDL_MouseButtonFlags
    x::Cfloat
    y::Cfloat
    xrel::Cfloat
    yrel::Cfloat
end

SDL_Init=(flag)->ccall((:SDL_Init, sdl3_lib),Cint,(SDL_InitFlags,),flag)
SDL_GetError=(flag)->ccall((:SDL_GetError, sdl3_lib),Cstring,(),)
SDL_CreateWindow=(title, w, h, flags)->ccall((:SDL_CreateWindow, sdl3_lib),SDL_Window_Ptr,(Cstring, Cint, Cint, SDL_WindowFlags),title,w,h,flags)
SDL_CreateRenderer=(win, name)->ccall((:SDL_CreateRenderer, sdl3_lib),SDL_Renderer_Ptr,(SDL_Window_Ptr, Cstring),win,name)
SDL_GetRendererName=(ren)->ccall((:SDL_GetRendererName, sdl3_lib),Cstring,(SDL_Renderer_Ptr,),ren)
SDL_PollEvent=(ev)->ccall((:SDL_PollEvent, sdl3_lib),Cint,(SDL_Event_Ptr,),ev)
SDL_GetTicks=()->ccall((:SDL_GetTicks, sdl3_lib),UInt64,(),)
SDL_GetKeyName=(keycode)->ccall((:SDL_GetKeyName, sdl3_lib),Cstring,(SDL_Keycode,),keycode)
SDL_RenderClear=(ren)->ccall((:SDL_RenderClear, sdl3_lib),Cbool,(SDL_Renderer_Ptr,),ren)
SDL_RenderFillRect=(ren, rect)->ccall((:SDL_RenderFillRect, sdl3_lib),Cbool,(SDL_Renderer_Ptr,Ref{SDL_FRect}),ren,rect)
SDL_SetRenderDrawColor=(ren, r, g, b, a)->ccall((:SDL_SetRenderDrawColor, sdl3_lib),Cbool,(SDL_Renderer_Ptr,UInt8,UInt8,UInt8,UInt8),ren,r,g,b,a)
SDL_RenderPresent=(ren)->ccall((:SDL_RenderPresent, sdl3_lib),Cbool,(SDL_Renderer_Ptr,),ren)

global running = true
global mouseRect::SDL_FRect = SDL_FRect(0, 0, 0, 0)
global renderer::SDL_Renderer_Ptr

function new_event()::SDL_Event_Ptr
    return Libc.malloc(128)
end

function free_event(ev::SDL_Event_Ptr)
    Libc.free(ev)
end

hex(s) = string(s, base=16)

function get_event_type(ev::SDL_Event_Ptr)::SDL_EventType
    tp=Ptr{UInt32}(ev)
    return UInt32(unsafe_load(tp))
end

function get_keyevent(ev::SDL_Event_Ptr)::SDL_KeyboardEvent
    tp=Ptr{SDL_KeyboardEvent}(ev)
    key_event = unsafe_load(tp)
    # println("KeyEvent: ", key_event)
    # println("isDown: ", key_event.down == 1 ," ( ", key_event.down," )")
    # println("isRepeat: ", key_event.repeat == 1 ," ( ", key_event.repeat," )")
    return key_event
end

function get_mousebuttonevent(ev::SDL_Event_Ptr)::SDL_MouseButtonEvent
    tp=Ptr{SDL_MouseButtonEvent}(ev)
    btn_event = unsafe_load(tp)
    # println("MouseButtonEvent: ", btn_event)
    # println("Button: ", btn_event.button)
    # println("isDown: ", btn_event.down == 1 ," ( ", btn_event.down," )")
    # println("Clicks: ", btn_event.clicks)
    # println("X: ", btn_event.x)
    # println("Y: ", btn_event.y)
    return btn_event
end

function get_mousemotionevent(ev::SDL_Event_Ptr)::SDL_MouseMotionEvent
    tp=Ptr{SDL_MouseMotionEvent}(ev)
    motion_event = unsafe_load(tp)
    # println("MouseMotionEvent: ", motion_event)
    # println("X: ", motion_event.x)
    # println("Y: ", motion_event.y)
    # println("Xrel: ", motion_event.xrel)
    # println("Yrel: ", motion_event.yrel)
    return motion_event
end

function get_event_scancode(ev::SDL_Event_Ptr)::SDL_Scancode
    key_event = get_keyevent(ev)
    return key_event.scancode
end

function get_event_keycode(ev::SDL_Event_Ptr)::SDL_Keycode
    scancode = get_event_scancode(ev)
    # println("Scancode: 0x", hex(scancode))
    keycode = UInt32(trunc(scancode / 0x100000000))
    # println("Keycode: 0x", hex(keycode))
    return keycode
end

function julia_main()
    try
        main()
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

function init()
    ret = SDL_Init(SDL_INIT_VIDEO)

    if ret < 0
        println("SDL_Init() Error: ", unsafe_string(SDL_GetError()))
        return
    end

    window = SDL_CreateWindow("HelloWorld SDL3", 640, 480, 0);
    if window == C_NULL
        println("SDL_CreateWindow() Error: ", unsafe_string(SDL_GetError()))
        return
    end

    global renderer = SDL_CreateRenderer(window, C_NULL);

    if renderer == C_NULL
        println("SDL_CreateRenderer() Error: ", unsafe_string(SDL_GetError()))
        return
    end

    renderer_name = unsafe_string(SDL_GetRendererName(renderer))
    println("Renderer: ", renderer_name)

    global running = true
end

global count = 0

function main()
    init()

    event::SDL_Event_Ptr = new_event()

    # ensure it's offscreen at startup
    global mouseRect.x = -1000
    global mouseRect.y = -1000

    global mouseRect.w = 50
    global mouseRect.h = 50

    while running
        while SDL_PollEvent(event) == 1
            event_type = get_event_type(event)
            # println("Event type: ", event_type)

            if event_type == SDL_EVENT_MOUSE_BUTTON_DOWN
                println("Mouse down")
                btn_event = get_mousebuttonevent(event)
            elseif event_type == SDL_EVENT_MOUSE_BUTTON_UP
                println("Mouse up")
                btn_event = get_mousebuttonevent(event)
            elseif event_type == SDL_EVENT_MOUSE_MOTION
                # println("Mouse move")
                motion_event = get_mousemotionevent(event)
                mouseRect.x = motion_event.x - (mouseRect.w / 2.0);
                mouseRect.y = motion_event.y - (mouseRect.h / 2.0);
            elseif event_type == SDL_EVENT_QUIT
                println("Quitting...")
                global running = false
                break
            elseif event_type == SDL_EVENT_KEY_DOWN
                println("Key down event")
                keycode = get_event_keycode(event)
                println("Keycode: ", keycode)
                println("Keyname: ", unsafe_string(SDL_GetKeyName(keycode)))

                if keycode == SDLK_ESCAPE
                    println("Escape!")
                    global running = false
                    break
                end
            elseif event_type == SDL_EVENT_KEY_UP
                println("Key up event")
                keycode = get_event_keycode(event)
                println("Keycode: ", keycode)
                println("Keyname: ", unsafe_string(SDL_GetKeyName(keycode)))
            else
                # println("Event type: ", event_type)
            end

            # global count += 1
            # if count > 1000
            #     break
            # end
        end

        sineWave = sin(((float(SDL_GetTicks() % 3000)) / 3000.0) * 2.0 * pi)
        r = UInt8(trunc(sineWave * 127.0 + 127))
        SDL_SetRenderDrawColor(renderer, r, 0, 0, 255)
        SDL_RenderClear(renderer)
        SDL_SetRenderDrawColor(renderer, 255, 255, 0, 255)
        SDL_RenderFillRect(renderer, mouseRect)
        # println("MouseRect: ", mouseRect)
        SDL_RenderPresent(renderer)
    end

    free_event(event)
end

end # module SDL3Test
