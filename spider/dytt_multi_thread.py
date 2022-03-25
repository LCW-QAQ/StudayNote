from concurrent import futures
from concurrent.futures import ThreadPoolExecutor
import re
from threading import Lock
import time
import requests

movieSeeds_Lock = Lock()

def f(url, title, movieSeeds, chainRe):
    # print(url, movieSeeds, chainRe)
    with requests.get(url) as resp2:
                resp2.encoding = "gbk"
                content = resp2.text
                m = chainRe.search(content)
                with movieSeeds_Lock:
                    movieSeeds.append({
                        "title": title,
                        "seed": m.group("seed")[:30]
                    })

if __name__ == "__main__":
    start = time.time()
    executor = ThreadPoolExecutor()
    domain = "https://m.dytt8.net/"
    url = "https://m.dytt8.net/index2.htm"
    ulRe = re.compile(r"新片精品.*?<ul>(?P<ul>.*?)</ul>", re.S)
    aRe = re.compile(r"]<a href='(?P<url>.*?)'>(?P<title>.*?)</a>", re.S)
    chainRe = re.compile(r'<a target=".*?" href="(?P<seed>.*?)">.*?磁力链.*?</font>', re.S)
    movieSeeds = []
    fs = []
    with requests.get(url) as resp:
        resp.encoding = "gbk"
        content = resp.text
        ulContent = ulRe.search(content).group("ul")
        for item in aRe.finditer(ulContent):
            child_href = domain + item.group("url").strip("/")
            title = item.group("title")
            future = executor.submit(f, child_href, title, movieSeeds, chainRe)
            fs.append(future)
            # with requests.get(child_href) as resp2:
            #     resp2.encoding = "gbk"
            #     content = resp2.text
            #     m = chainRe.search(content)
            #     movieSeeds[title] = m.group("seed")
    futures.wait(fs)
    for item in movieSeeds:
        print(item)
    print("耗时:", time.time() - start)