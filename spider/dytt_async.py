import asyncio
import aiohttp
import re
import time

movieSeeds_Lock = asyncio.Lock()

async def main():
    tasks = [asyncio.create_task(taskOne())]
    await asyncio.wait(tasks)

async def taskOne():
    async def f(session, url, movieSeeds, title, chainRe):
        async with session.get(url) as resp2:
                        resp2.encoding = "gbk"
                        content = await resp2.text()
                        m = chainRe.search(content)
                        async with movieSeeds_Lock:
                            movieSeeds.append({
                                    "title": title,
                                    "seed": m.group("seed")[:10]
                                })

    domain = "https://m.dytt8.net/"
    url = "https://m.dytt8.net/index2.htm"
    ulRe = re.compile(r"新片精品.*?<ul>(?P<ul>.*?)</ul>", re.S)
    aRe = re.compile(r"]<a href='(?P<url>.*?)'>(?P<title>.*?)</a>", re.S)
    chainRe = re.compile(r'<a target=".*?" href="(?P<seed>.*?)">.*?磁力链.*?</font>', re.S)
    movieSeeds = []
    tasks = []
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as resp:
            content = await resp.text()
            ulContent = ulRe.search(content).group("ul")
            for item in aRe.finditer(ulContent):
                child_href = domain + item.group("url").strip("/")
                title = item.group("title")
                tasks.append(asyncio.create_task(f(session, child_href, movieSeeds, title, chainRe)))
        await asyncio.wait(tasks)
    for item in movieSeeds:
        print(item)

if __name__ == "__main__":
    start = time.time()
    asyncio.get_event_loop().run_until_complete(main())
    print("耗时:", time.time() - start)