# Docker

> 一项应用容器技术, 相关只是请查阅资料

## 部署

centos下运行 `yum install docker-ce`即可安装最新版

## 命令

参考[官网](https://www.docker.com/)或[菜鸟教程](https://www.runoob.com/docker/docker-command-manual.html)

这里只列出常用命令

1. docker build 根据Dockerfile构建image
    - docker build . -t image_name:image_tag 根据当前目录下的Dockerfile构建名称为image_name, tag为image_tag的镜像
2. docker run 根据指定镜像运行容器
    - docker run image_name:image_tag 不加任何参数 只会创建容器不会运行
    - docker run -it image_name:image_tag 运行指定镜像, i表示以交互模式运行, t表示给容器分配一个伪终端, it通常一起使用
        - 若退出终端, 容器也会关闭
    - --rm 表示不保存容器资源, 容器关闭后自动清理容器内部的用户数据, 用于开发测试
    - -d 后台运行容器
    - --name 指定该容器的名称
    - docker run -it --rm image_name:image_tag /bin/bash 表示运行容器时, 会执行的命令, 会覆盖Dockerfile中的cmd
    - -P 启动一个容器,并将容器的80端口映射到主机随机端口。
    - -p 80:80 启动一个容器,并将容器的80端口映射到主机的80端口
3. docker ps
    - docker ps 显示正在运行的容器
    - docker ps -a 显示所有容器
4. docker rm 容器名称或容器id, 删除指定容器
5. docker rmi image_name:image_tag 删除指定镜像
6. docker start 容器名称或容器id 启动指定容器
7. docker stop 容器名称或容器id 关闭指定容器
8. docker stats 容器名称或容器id 显示容器状态
9. docker search 搜索镜像, 详细版本信息请直接访问dockerhub网站

## Dockerfile

![Dockerfile指令](Docker.assets/Dockerfile指令.png)

### 注意事项

1. 尽量使用alpline、slim、small等最小化镜像, 减少镜像大小

2. 尽量使用已有官方的镜像为底镜像构建

3. 在无需自动解压的情况下使用`COPY`替代`ADD`

4. 将可以写在一起的命令用`&`连接, 每个RUN都会创建一层镜像

    - ```dockerfile
        FROM centos
        RUN yum install vim && yum install nginx && yum install redis
        ```

5. 在使用包管理器安装时, 记得清除缓存、无用安装包

    - ```dockerfile
        FROM centos
        RUN yum install vim && yum clean all
        ```

6. 将经常更改的文件, 尽可能写在靠下面, 为了容器更快找到文件

    - 容器中没有需要的文件时, 会一次向下从镜像中寻找, Dockerfile构建镜像时类似栈结构, 后面的镜像会在上层, 可以更快找到

7. 使用`ETRNTPOINT` + 脚本, 便于管理使用

8. 使用多段构建multi-stage

    - ```dockerfile
        FROM golang:1.9-alpine as builder    
        RUN apk --no-cache add git
        WORKDIR /go/src/github.com/go/helloworld/
        RUN go get -d -v github.com/go-sql-driver/mysql
        COPY app.go .
        RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .
        
        FROM alpine:latest as prod
        RUN apk --no-cache add ca-certificates
        WORKDIR /root/
        COPY --from=0 /go/src/github.com/go/helloworld/app .
        CMD ["./app"]  
        ```

## 私有仓库

### registry

> 极为简单的仓库, 超轻量, 只有基本上传下载功能, 因此不常用, 可以用作demo~

docker客户端想要从第三方仓库拉取镜像需要配置`/etc/docker/daemon.json`

```json
{
    // 表示信任的第三发仓库
    "insecure-registries": ["192.168.150.101:5000", "harbor.captain.com"], 
    // 镜像加速
    "registry-mirrors": ["https://660k0t5z.mirror.aliyuncs.com"]
}
```

生成registry仓库的tag `docker tag 镜像id 镜像服务地址/子目录/镜像名:镜像tag`

生成对应tag后, 运行`docker push 镜像id 镜像服务地址/子目录/镜像名:镜像tag` 即可上传至registry仓库

### harbor

> 企业级容器仓库, 使用go开发

[github仓库](https://github.com/goharbor/harbor)

按需求下载offline或online版

解压后配置harbor.yml

```yml
# 主机名
hostname: harbor.captain.com
http:
  # port for http, default is 80. If https enabled, this port will redirect to https port
  port: 80
# https: 不适用https记得注释掉
# harbor admin 账户密码
harbor_admin_password: Harbor12345
# harbor数据目录, harbor也是以容器方式运行, 这个目录是容器内镜像数据挂载的目录
data_volume: /data/harbor
```

安装docker-compose, `yum install -y docker-compose`, 最好在harbor目录或单独的docker-compose目录安装, 安装后当前目录会有一些docker-compose依赖的配置文件, 没有配置文件docker-compose无法运行

运行`sh install.sh`脚本自动部署harbor



docker客户端想要从第三方仓库拉取镜像需要配置`/etc/docker/daemon.json`

```json
{
    // 表示信任的第三发仓库
    "insecure-registries": ["192.168.150.101:5000", "harbor.captain.com"], 
    // 镜像加速
    "registry-mirrors": ["https://660k0t5z.mirror.aliyuncs.com"]
}
```



生成harbor仓库的tag `docker tag 镜像id 镜像服务地址/子目录/镜像名:镜像tag`

生成对应tag后, 运行`docker push 镜像id 镜像服务地址/子目录/镜像名:镜像tag` 即可上传至harbor仓库