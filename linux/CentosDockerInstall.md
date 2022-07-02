# CentosDockerInstall

> Centos7 Docker快速部署文档

## 部署

### 使用官方脚本安装

安装命令如下：

```bash
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
```

也可以使用国内 daocloud 一键安装命令：

```bash
curl -sSL https://get.daocloud.io/docker | sh
```

### 手动安装

卸载旧版本

```bash
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
```

#### 安装 Docker Engine-Community

使用 Docker 仓库进行安装

设置仓库

安装所需的软件包。yum-utils 提供了 yum-config-manager ，并且 device mapper 存储驱动程序需要 device-mapper-persistent-data 和 lvm2。

使用官方源地址（比较慢）

```bash
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```

阿里云

```bash
sudo yum-config-manager \
    --add-repo \
    http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

安装最新版本的 Docker Engine-Community 和 containerd，或者转到下一步安装特定版本：

```bash
sudo yum install docker-ce docker-ce-cli containerd.io
```

要安装特定版本的 Docker Engine-Community，请在存储库中列出可用版本，然后选择并安装：

1、列出并排序您存储库中可用的版本。此示例按版本号（从高到低）对结果进行排序

```bash
yum list docker-ce --showduplicates | sort -r
```

```bash
sudo yum install docker-ce-<VERSION_STRING> docker-ce-cli-<VERSION_STRING> containerd.io
```

启动Docker

```bash
sudo systemctl start docker
```

运行HelloWorld程序测试

```bash
sudo docker run hello-world
```

设置Docker开机自启

```bash
systemctl enable docker
```

## 卸载Docker

卸载 docker
删除安装包：

```bash
yum remove docker-ce
```

删除镜像、容器、配置文件等内容：

```bash
rm -rf /var/lib/docker
```

## DcokerCompose安装

DockerCompose使用二进制文件发行, 直接去github下载二进制文件即可

```bash
curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
```

赋予文件可执行权限

```bash
chmod +x /usr/local/bin/docker-compose
```

检查安装是否成功

```bash
docker-compose -v
```
