```js
export function downloadFile(blobObj, name, suffix) {
    const url = window.URL.createObjectURL(new Blob([blobObj]))
    const link = document.createElement("a")
    link.style.display = "none"
    link.href = url
    const fileName = new Date() + "-" + name + "." + suffix
    link.setAttribute("download", fileName)
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
}
```

