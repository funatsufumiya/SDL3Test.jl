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

# const uiControl = Ptr{Cvoid}
# const uiButton = Ptr{Cvoid}
# const uiGrid = Ptr{Cvoid}
# const OnClosingFuncType = Ptr{Cvoid}
# const UserData = Ptr{Cvoid}

# const uiAlign = Cint
# uiAlignFill::Cint = 0
# uiAlignStart::Cint = 1
# uiAlignCenter::Cint = 2
# uiAlignEnd::Cint = 3

const Cbool = UInt8

const SDL_InitFlags = Cuint
const SDL_INIT_VIDEO::Cuint = 0x00000020

const SDL_WindowFlags = Cuint

const SDL_EventType = UInt32
const SDL_EVENT_QUIT::UInt32 = 0x100
const SDL_EVENT_KEY_DOWN::UInt32 = 0x300
const SDL_EVENT_KEY_UP::UInt32 = 0x301

const SDL_Keycode = UInt32
const SDLK_RETURN = 0x0000000d
const SDLK_ESCAPE = 0x0000001b

const SDL_WindowID = UInt32
const SDL_KeyboardID = UInt32
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

SDL_Init=(flag)->ccall((:SDL_Init, sdl3_lib),Cint,(SDL_InitFlags,),flag)
SDL_GetError=(flag)->ccall((:SDL_GetError, sdl3_lib),Cstring,(),)
SDL_CreateWindow=(title, w, h, flags)->ccall((:SDL_CreateWindow, sdl3_lib),SDL_Window_Ptr,(Cstring, Cint, Cint, SDL_WindowFlags),title,w,h,flags)
SDL_CreateRenderer=(win, name)->ccall((:SDL_CreateRenderer, sdl3_lib),SDL_Renderer_Ptr,(SDL_Window_Ptr, Cstring),win,name)
SDL_GetRendererName=(ren)->ccall((:SDL_GetRendererName, sdl3_lib),Cstring,(SDL_Renderer_Ptr,),ren)
SDL_PollEvent=(ev)->ccall((:SDL_PollEvent, sdl3_lib),Cint,(SDL_Event_Ptr,),ev)
SDL_GetKeyName=(keycode)->ccall((:SDL_GetKeyName, sdl3_lib),Cstring,(SDL_Keycode,),keycode)

global running = true

# global w::uiWindow

# function onClose(w::uiWindow, data::UserData)::Cint
#     global already_quitted = true
#     uiQuit()
#     return 1
# end

# function onMsgBoxClick(b::uiButton, data::UserData)
# 	uiMsgBox(w,
# 	    "This is a normal message box.",
# 		"More detailed information can be shown here.")
# end

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

    renderer = SDL_CreateRenderer(window, C_NULL);

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

    while running
        while SDL_PollEvent(event) == 1
            event_type = get_event_type(event)
            # println("Event type: ", event_type)

            if event_type >= 1024
                # just ignore
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
    end

    free_event(event)

    # opt = uiInitOptions(0)
    # # opt_ptr = Ref(opt)

    # err = uiInit(opt)
    # if err != C_NULL
    #     println("Error initializing libui-ng: ", err)
    #     uiFreeInitError(err)
    # end

    # onClosing = @cfunction(onClose, Cint, (uiWindow, UserData))
    # onMsgBoxClicked = @cfunction(onMsgBoxClick, Cvoid, (uiControl, UserData))

    # global w = uiNewWindow("Hello World", 300, 300, 0)
    # grid = uiNewGrid()
    # uiGridSetPadded(grid, 1)

    # button = uiNewButton("Message Box")
    # uiButtonOnClicked(button, onMsgBoxClicked, C_NULL);

    # uiGridAppend(grid, button,
	# 	0, 0, 1, 1,
	# 	0, uiAlignFill, 0, uiAlignFill);

    # uiWindowSetChild(w, grid);
    # # uiWindowSetChild(w, button);

    # # println("window: ", w)
    # # println("grid: ", grid)

    # uiWindowOnClosing(w, onClosing, C_NULL);
    # uiControlShow(w)

    # try
    #     uiMain()
    # finally
    #     # println("already_quitted: ", (already_quitted))
    #     if !(already_quitted)
    #         uiUninit()
    #     end
    # end
end

end # module SDL3Test
