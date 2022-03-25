import csv
from random import triangular
import re
import requests

if __name__ == "__main__":
    url = "https://movie.douban.com/top250"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Safari/537.36"
    }
    params = {
        "start": 25 * 9
    }
    titleRe = re.compile(r'<li>.*?<div class="item">.*?<span class="title">(?P<title>.*?)</span>'
                         r'.*?<p class="">.*?<br>(?P<year>.*?)&nbsp'
                         r'.*?<span class="rating_num" property="v:average">(?P<score>.*?)</span>'
                         r'.*?<span>(?P<num>.*?)人评价</span>', re.S)
    with open("data.csv", "w") as f:
        csvwriter = csv.writer(f)
        with requests.get(url, params, headers=headers) as resp:
            content = resp.text
            for item in titleRe.finditer(content):
                # print(item.group("title"), item.group("year").strip(), item.group("score"), item.group("num"))
                dic = item.groupdict()
                dic["year"] = dic["year"].strip()
                csvwriter.writerow(dic.values())