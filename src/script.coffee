$ = (sel) -> document.querySelector sel

inputItems = ['text', 'color', 'alpha', 'angle', 'space', 'size']
input = {}

image = $ '#image'
textInput = $ '#text'
downloadButton = $ '#download'
pcanvas = $ '#preview-canvas'
previewPlaceholder = $ '#preview-placeholder'
uploadArea = $ '#upload-area'
graph = $ '#graph'
refresh = $ '#refresh'
autoRefresh = $ '#auto-refresh'
file = null
canvas = null
textCtx = null
redraw = null

dataURItoBlob = (dataURI) ->
    binStr = atob (dataURI.split ',')[1]
    len = binStr.length
    arr = new Uint8Array len

    for i in [0..len - 1]
        arr[i] = binStr.charCodeAt i


generateFileName = ->
    pad = (n) -> if n < 10 then '0' + n else n

    d = new Date
    '' + d.getFullYear() + '-' + (pad d.getMonth() + 1) + '-' + (pad d.getDate()) + ' ' + \
        (pad d.getHours()) + (pad d.getMinutes()) + (pad d.getSeconds()) + '.png'


readFile = ->
    return if not file?

    fileReader = new FileReader

    fileReader.onload = ->
        img = new Image
        img.onload = ->
            # previewPlaceholder.style.display = 'none'
            # pcanvas.style.display = 'block'
            # refresh.disabled = false
            # downloadButton.disabled = false
            canvas = document.createElement 'canvas'
            canvas.width = img.width
            canvas.height = img.height
            textCtx = null
            
            ctx = canvas.getContext '2d'
            ctx.drawImage img, 0, 0

            redraw = ->
                ctx.clearRect 0, 0, canvas.width, canvas.height
                ctx.drawImage img, 0, 0
            
            drawText()

            graph.innerHTML = ''
            graph.appendChild canvas

            canvas.addEventListener 'click', ->
                link = document.createElement 'a'
                link.download = generateFileName()
                imageData = canvas.toDataURL 'image/png'
                blob = dataURItoBlob imageData
                link.href = URL.createObjectURL blob
                graph.appendChild link

                setTimeout ->
                    link.click()
                    graph.removeChild link
                , 100
                


        img.src = fileReader.result

    fileReader.readAsDataURL file

    # 更新上传区域显示
    fileName = if file.name.length > 25 then file.name.substring(0, 22) + '...' else file.name
    uploadArea.querySelector('.file-upload-text').innerHTML = "<strong>#{fileName}</strong><br>点击可重新选择图片"
    uploadArea.querySelector('.file-upload-btn').textContent = '更换图片' 
    

makeStyle = ->
    match = input.color.value.match /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i

    'rgba(' + (parseInt match[1], 16) + ',' + (parseInt match[2], 16) + ',' \
         + (parseInt match[3], 16) + ',' + input.alpha.value + ')'


drawText = ->
    return if not canvas?
    textSize = input.size.value * Math.max 15, (Math.min canvas.width, canvas.height) / 25
    
    if textCtx?
        redraw()
    else
        textCtx = canvas.getContext '2d'
    
    textCtx.save()
    textCtx.translate(canvas.width / 2, canvas.height / 2)
    textCtx.rotate (input.angle.value) * Math.PI / 180

    textCtx.fillStyle = makeStyle()
    textCtx.font = 'bold ' + textSize + 'px -apple-system,"Helvetica Neue",Helvetica,Arial,"PingFang SC","Hiragino Sans GB","WenQuanYi Micro Hei",sans-serif'
    
    width = (textCtx.measureText input.text.value).width
    step = Math.sqrt (Math.pow canvas.width, 2) + (Math.pow canvas.height, 2)
    margin = (textCtx.measureText '啊').width

    x = Math.ceil step / (width + margin)
    y = Math.ceil (step / (input.space.value * textSize)) / 2

    for i in [-x..x]
        for j in [-y..y]
            textCtx.fillText input.text.value, (width + margin) * i, input.space.value * textSize * j
    
    textCtx.restore()
    return


image.addEventListener 'change', ->
    file = @files[0]

    return alert '仅支持 png, jpg, gif 图片格式' if file.type not in ['image/png', 'image/jpeg', 'image/gif']
    readFile()

# 文件上传区域交互效果
uploadArea.addEventListener 'dragover', (e) ->
  e.preventDefault()
  uploadArea.style.borderColor = '#4a6cf7'
  uploadArea.style.backgroundColor = '#f0f4ff'

uploadArea.addEventListener 'dragleave', ->
  uploadArea.style.borderColor = '#d1d8e0'
  uploadArea.style.backgroundColor = '#fdfdfd'

uploadArea.addEventListener 'drop', (e) ->
  e.preventDefault()
  uploadArea.style.borderColor = '#d1d8e0'
  uploadArea.style.backgroundColor = '#fdfdfd'
  
  if e.dataTransfer.files and e.dataTransfer.files[0]
    imageInput.files = e.dataTransfer.files
    file = e.dataTransfer.files[0]
    return alert '仅支持 png, jpg, gif 图片格式' if file.type not in ['image/png', 'image/jpeg', 'image/gif']
    readFile()

# 下载功能
downloadButton.addEventListener 'click', ->
  return unless currentImage
  
  link = document.createElement('a')
  link.download = 'watermarked-image.png'
  link.href = canvas.toDataURL('image/png')
  link.click()
  
  # 添加下载成功反馈
  originalText = downloadButton.innerHTML
  downloadButton.innerHTML = '<i class="fas fa-check"></i> 下载完成'
  downloadButton.style.background = 'linear-gradient(90deg, #2ecc71, #1abc9c)'
  
  setTimeout ->
    downloadButton.innerHTML = originalText
    downloadButton.style.background = ''
  , 2000


inputItems.forEach (item) ->
    el = $ '#' + item
    input[item] = el

    autoRefresh.addEventListener 'change', ->
        if @checked
            refresh.setAttribute 'disabled', 'disabled'
        else
            refresh.removeAttribute 'disabled'
    
    el.addEventListener 'input', ->
        drawText() if autoRefresh.checked

    refresh.addEventListener 'click', drawText

