import re
import time
import requests

if __name__ == "__main__":
    start = time.time()
    domain = "https://m.dytt8.net/"
    url = "https://m.dytt8.net/index2.htm"
    ulRe = re.compile(r"新片精品.*?<ul>(?P<ul>.*?)</ul>", re.S)
    aRe = re.compile(r"]<a href='(?P<url>.*?)'>(?P<title>.*?)</a>", re.S)
    chainRe = re.compile(r'<a target=".*?" href="(?P<seed>.*?)">.*?磁力链.*?</font>', re.S)
    movieSeeds = []
    with requests.get(url) as resp:
        resp.encoding = "gbk"
        content = resp.text
        ulContent = ulRe.search(content).group("ul")
        for item in aRe.finditer(ulContent):
            child_href = domain + item.group("url").strip("/")
            title = item.group("title")
            with requests.get(child_href) as resp2:
                resp2.encoding = "gbk"
                content = resp2.text
                m = chainRe.search(content)
                movieSeeds.append({
                        "title": title,
                        "seed": m.group("seed")[:10]
                    })
    for item in movieSeeds:
        print(item)
    print("耗时:", time.time() - start)