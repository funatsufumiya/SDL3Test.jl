module SDL3Test

sdl3_lib = "libSDL3.so"

@static if Sys.iswindows()
   sdl3_lib = "libSDL3.dll"
elseif Sys.isapple()
   sdl3_lib = "libSDL3.dylib"
else
   sdl3_lib = "libSDL3.so"
end

# mutable struct uiInitOptions 
#     Size::Csize_t
# end

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

const SDL_InitFlags = Cuint
const SDL_INIT_VIDEO::Cuint = 0x00000020

const SDL_WindowFlags = Cuint

SDL_Init=(flag)->ccall((:SDL_Init, sdl3_lib),Cint,(SDL_InitFlags,),flag)
SDL_GetError=(flag)->ccall((:SDL_GetError, sdl3_lib),Cstring,(),)
SDL_CreateWindow=(title, w, h, flags)->ccall((:SDL_CreateWindow, sdl3_lib),SDL_Window_Ptr,(Cstring, Cint, Cint, SDL_WindowFlags),title,w,h,flags)
SDL_CreateRenderer=(win, name)->ccall((:SDL_CreateRenderer, sdl3_lib),SDL_Renderer_Ptr,(SDL_Window_Ptr, Cstring),win,name)
SDL_GetRendererName=(ren)->ccall((:SDL_GetRendererName, sdl3_lib),Cstring,(SDL_Renderer_Ptr,),ren)
SDL_PollEvent=(ev)->ccall((:SDL_PollEvent, sdl3_lib),Cint,(SDL_Event_Ptr,),ev)

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

function main()
    init()

    event::SDL_Event_Ptr = Libc.malloc(128)

    while running
        while SDL_PollEvent(event) == 1
            sleep(1.0)
            break
        end
        
        break
    end

    Libc.free(event)

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
