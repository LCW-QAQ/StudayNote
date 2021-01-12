project(democpp)

aux_source_directory(. dir_src)
aux_source_directory(./EnumDemo enum_demo)
add_executable(main ${dir_src} ${enum_demo})