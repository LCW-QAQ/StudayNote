# Ubuntu换源

## 备份源

```bash
cp /etc/apt/sources.list /etc/apt/sources.list.bak
```

## 写入国内源

```bash
echo 'deb http://mirrors.163.com/debian/ stretch main non-free contrib' > /etc/apt/sources.list
echo 'deb http://mirrors.163.com/debian/ stretch-updates main non-free contrib' >> /etc/apt/sources.list
echo 'deb http://mirrors.163.com/debian-security/ stretch/updates main non-free contrib' >> /etc/apt/sources.list
```

## 更新源

```bash
apt-get update
```
