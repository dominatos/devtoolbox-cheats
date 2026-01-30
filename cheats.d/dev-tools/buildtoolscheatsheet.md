Title: 🛠️ Build — Make/CMake
Group: Dev & Tools
Icon: 🛠️
Order: 5

cmake -S . -B build -DCMAKE_BUILD_TYPE=Release  # Generate build tree / Сгенерировать дерево сборки
cmake --build build -j$(nproc)                  # Build with parallelism / Сборка с параллелизмом
make -j$(nproc) && sudo make install            # Build/install (Makefile) / Сборка/установка (Makefile)

