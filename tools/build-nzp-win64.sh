cd ../engine
make makelibs FTE_TARGET=win64_SDL2 && make m-rel FTE_TARGET=win64_SDL2 FTE_CONFIG=nzportable -j32
# Running make once is not sufficient... there are link errors (undefined reference to SDL's functions).
# Doing it twice works. I don't know why.
make m-rel FTE_TARGET=win64_SDL2 FTE_CONFIG=nzportable -j32
# Copy SDL2.dll next to the exe so the game is immediately runnable on Windows.
cp libs-x86_64-w64-mingw32/SDL2-2.30.7/x86_64-w64-mingw32/bin/SDL2.dll release/
