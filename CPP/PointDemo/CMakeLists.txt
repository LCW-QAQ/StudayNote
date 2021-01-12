project(point_demo)

aux_source_directory(. dir_src)
aux_source_directory(./util util_src)

add_executable(main ${dir_src} ${util_src})