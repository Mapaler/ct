// JavaScript Document
var picsa = new Array;
class PicObj {
	file = null;
	img = null;
	dpix = 0x0b12;
	dpiy = 0x0b12;
	canvas = document.createElement("canvas");
	constructor(file) {
		this.file = file;
		const _this = this;
		file.arrayBuffer().then(buffer=>{
			const dv = new DataView(buffer);
			switch (file.type) {
				case "image/bmp": {
					_this.dpix = dv.getUint32(0x26,true);
					_this.dpiy = dv.getUint32(0x2A,true);
					break;
				}
				case "image/png": {
					_this.dpix = dv.getUint32(0x352);
					_this.dpiy = dv.getUint32(0x356);
					break;
				}
				case "image/jpeg": {
					_this.dpix = dv.getUint16(0xe) * 39.37;
					_this.dpiy = dv.getUint16(0x10) * 39.37;
					break;
				}
			}
		});
		this.img = new Image(URL.createObjectURL(file));
		this.img.onload=function(event){
			console.log(event);
			var draw_canvas = thispic.getElementsByClassName("view").item(0).getElementsByClassName("draw-canvas").item(0);
			draw_canvas.width = picobj.img.width;
			draw_canvas.height = picobj.img.height;
			
			drawview(thispic); //画图
			picture_info.innerHTML = "图片预览";
		};
	}
}
function picObj(){ //use factory
	var obj=new Object();
	obj.file = null;
	obj.blod = null;
	obj.dpix = null;
	obj.dpiy = null;
	obj.img = new Image();
	obj.canvas = document.createElement("canvas");
	return obj;
}

function imagesSelected(myFiles) {
  for (var i = 0, f; f = myFiles[i]; i++) {
    var imageReader = new FileReader();
	imageReader.onload = (function(aFile) {
      return function(e) {
		var imgbin = e.target.result;
		var dv = new DataView(imgbin);
		var  arr = new Uint8Array(imgbin);
		console.log(typeof arr);
		console.log(arr.length);
		console.log(typeof arr[0]);
		//var fileheader = dv.getUint16(0x0);
		//if(fileheader != 0x424d)
		if(aFile.type == "image/bmp")
		{
			var dpix = dv.getUint32(0x26,true);
			var dpiy = dv.getUint32(0x2A,true);
		}else if(aFile.type == "image/png")
		{
			var dpix = dv.getUint32(0x352);
			var dpiy = dv.getUint32(0x356);
		}else if(aFile.type == "image/jpeg")
		{
			var dpix = dv.getUint16(0xe) * 39.37;
			var dpiy = dv.getUint16(0x10) * 39.37;
		}else
		{
			var dpix = 0x0b12;
			var dpiy = 0x0b12;
		}
		//document.getElementById('thumbs').innerHTML = ['分辨率为：', changeTwoDecimal(1e6 / dpix) , 'μm'].join('');
		/*var img = new Image();
		img.src = window.URL.createObjectURL(aFile);
		var cavans = document.createElement("canvas");*/
		
		//建立一个新的图片到内存中
		var picobj = new picObj();
		picobj.file = aFile;
		picobj.blod = e.target.result;
		picobj.dpix = dpix;
		picobj.dpiy = dpiy;
		picobj.img.src = window.URL.createObjectURL(aFile);
		var thispicindex = picsa.length;
		// const picobj = new PicObj(aFile);
		picsa.push(picobj);
		
		//复制图像控制栏
		var pictures_ul = document.getElementById("pictures");
		if (thispicindex>0){
			firstPic = pictures_ul.getElementsByClassName("picture").item(0);
			pictures_ul.appendChild(firstPic.cloneNode(true));
		}
		var thispic = pictures.getElementsByClassName("picture").item(thispicindex);
		var picture_info = thispic.getElementsByClassName("view").item(0).getElementsByClassName("picture-info").item(0);
		picture_info.innerHTML = "正在加载图片...";
		
		convertDpiNum(thispic); //设定图片DPI
		
		//图片加载成功时画图
		picobj.img.onload=function(event){
			console.log(event);
			var draw_canvas = thispic.getElementsByClassName("view").item(0).getElementsByClassName("draw-canvas").item(0);
			draw_canvas.width = picobj.img.width;
			draw_canvas.height = picobj.img.height;
			
			drawview(thispic); //画图
			picture_info.innerHTML = "图片预览";
		};
      };
    })(f);
	imageReader.readAsArrayBuffer(f);
  }
}

function dropIt(e) {  
   imagesSelected(e.dataTransfer.files); 
   e.stopPropagation();  
   e.preventDefault();   
}

function getDownLink(picdom){
	var domindex = Index(picdom);//获取li编号
	var pic = picsa[domindex];
	var outbarDom = picdom.getElementsByClassName("outbar").item(0);
	var downLinkDom = picdom.getElementsByClassName("outbar").item(0).getElementsByClassName("download-picture").item(0);
	if(downLinkDom == undefined){
		downLinkDom = document.createElement("a");
		downLinkDom.className = "download-picture";
		downLinkDom.target = "_blank";
	}else{
		downLinkDom = downLinkDoms.item(0);
	}
	downLinkDom.innerHTML = "正在准备数据...";
	
	var dotPos = pic.file.name.lastIndexOf(".");
	var shortName = pic.file.name.substring(0, dotPos) + "_scale";
	downLinkDom.download = shortName;
	outbarDom.appendChild(downLinkDom);
	
	if(typeof(pic.canvas.toBlob) == "function"){
		//只有火狐支持
		pic.canvas.toBlob(function(blob) {
			window.URL.revokeObjectURL(downLinkDom.href);
			var downLink = window.URL.createObjectURL(blob);
			//window.open(downLink);
			downLinkDom.title = "点击下载完整大小图片";
			downLinkDom.innerHTML = "下载图片";
			downLinkDom.href = downLink;
		});
	}else
	{
		var downLink = pic.canvas.toDataURL();
			downLinkDom.title = "点击下载完整大小图片";
		downLinkDom.innerHTML = "下载图片";
		downLinkDom.href = downLink;
		//window.open(downLink);
	}
}
function drawview(picdom){
	var domindex = Index(picdom);//获取li编号
	var drawCanvas = picdom.getElementsByClassName("view").item(0).getElementsByClassName("draw-canvas").item(0);
	var showContext = drawCanvas.getContext("2d");
	var pic = picsa[domindex];
	var img = pic.img;
	
	if((img.width / img.height) > (drawCanvas.width / drawCanvas.height)){
		var drawRatio = drawCanvas.width / img.width;
	}else{
		var drawRatio = drawCanvas.height / img.height;
	}
	/*var drawWidth = img.width * drawRatio;
	var drawHeight = img.height * drawRatio;*/
	
	var show_unit = parseInt(picdom.getElementsByClassName("show-unit").item(0).value);
	var decimal_digits = parseInt(picdom.getElementsByClassName("decimal-digits").item(0).value);
	
	var line_length = parseInt(picdom.getElementsByClassName("line-length").item(0).value);
	var line_width = parseInt(picdom.getElementsByClassName("line-width").item(0).value);
	var line_color = picdom.getElementsByClassName("line-color").item(0).value;
	
	var font_weight = picdom.getElementsByClassName("font-weight").item(0).checked
		? picdom.getElementsByClassName("font-weight").item(0).value
		: ""; //如果被选中则返回值，否则返回空
	var font_size = parseInt(picdom.getElementsByClassName("font-size").item(0).value);
	var font_family = picdom.getElementsByClassName("font-family").item(0).value;
	var font_color = picdom.getElementsByClassName("font-color").item(0).value;
	
	var space_width = parseInt(picdom.getElementsByClassName("space-width").item(0).value);
	var shadow_color = picdom.getElementsByClassName("shadow-color").item(0).value;
	var shadow_blur = parseInt(picdom.getElementsByClassName("shadow-blur").item(0).value);
	
	var position_horizontal = parseInt(picdom.getElementsByClassName("position-horizontal").item(0).value);
	var position_vertical = parseInt(picdom.getElementsByClassName("position-vertical").item(0).value);
	
	pic.canvas.width = img.width;
	pic.canvas.height = img.height;
	var downContext = pic.canvas.getContext("2d");
	drawscale(downContext,img,pic.dpix,pic.dpiy,
		show_unit,decimal_digits,
		line_length,line_width,line_color,
		font_weight,font_size,font_family,font_color,
		space_width,shadow_color,shadow_blur,
		position_horizontal,position_vertical
		);//作画函数
	
	var downLinkDom = picdom.getElementsByClassName("download-picture").item(0);
	if(downLinkDom!= undefined)
	{
		window.URL.revokeObjectURL(downLinkDom.href);
		downLinkDom.parentNode.removeChild(downLinkDom); 
	}
	/* //每次操作都刷新下载链接
	pic.canvas.toBlob(function(blob) {
		var downLink = window.URL.createObjectURL(blob);
		downLinkDom.href = downLink;
	});
	*/
	
	showContext.clearRect(0,0,drawCanvas.width,drawCanvas.height); //清空画布
	//showContext.scale(drawRatio, drawRatio); //修改作画比率
	showContext.drawImage(pic.canvas,0,0,pic.canvas.width * drawRatio,pic.canvas.height * drawRatio);
	/*drawscale(showContext,img,pic.dpix,pic.dpiy,
		show_unit,decimal_digits,
		line_length,line_width,line_color,
		font_weight,font_size,font_family,font_color,
		space_width,shadow_color,shadow_blur,
		position_horizontal,position_vertical
		);//作画函数
		*/
	//showContext.scale(1/drawRatio, 1/drawRatio); //恢复作画比率
	
}

//画图函数
function drawscale(context,img,dpiX,dpiY,
	showUnit,decimalDigits,
	lineLength,lineWidth,lineColor,
	fontWeight,fontSize,fontFamily,fontColor,
	spaceWidth,shadowColor,shadowBlur,
	positionHorizontal,positionVertical
	)
{
	context.drawImage(img,0,0);
	context.beginPath();
	context.shadowBlur = shadowBlur;
	context.shadowColor = shadowColor;
	//context.fillStyle = "rgb(250,0,0)";
	
	var pixelSize = 1 / dpiX;
	var realLengthNum = pixelSize * lineLength * Math.pow(10,showUnit);
	var unitText="";
	switch (showUnit)
	{
		case 9:unitText="nm";break;
		case 6:unitText="μm";break;
		case 3:unitText="mm";break;
		case 2:unitText="cm";break;
		case 0:unitText="m";break;
	}
	
	context.fillStyle = fontColor;
	context.font= [
		fontWeight,
		fontSize + "px ",
		fontFamily
		].join(" ");
	context.textAlign = "center";
	context.textBaseline = "bottom";
	var scaleText = changeDecimal(realLengthNum,decimalDigits) + " " + unitText;
	
	var textWidth = context.measureText(scaleText).width;
	var scaleWidth = textWidth > lineLength ? textWidth : lineLength;
	var scaleHeight = fontSize + lineWidth + spaceWidth;
	
	var left = (img.width - scaleWidth) * positionHorizontal / 100;
	var top = (img.height - scaleHeight) * positionVertical / 100;
	
	context.fillText(scaleText,left + scaleWidth / 2,top + fontSize);
	
	context.strokeStyle = lineColor;
	context.lineWidth = lineWidth;
	scaleWidth 
	context.moveTo(left + (scaleWidth - lineLength) / 2,top + fontSize + spaceWidth + lineWidth /2);
	context.lineTo(left + (scaleWidth + lineLength) / 2,top + fontSize + spaceWidth + lineWidth /2);
    context.stroke();
	context.closePath();
}

/*功能：将浮点数四舍五入，取小数点后length位
用法：changeTwoDecimal(3.1415926,2) 返回 3.14
changeTwoDecimal(3.1475926,2) 返回 3.15*/
function changeDecimal(x,length)
{
	if(length == undefined) length= 2;
	var f_x = parseFloat(x);
	if (isNaN(f_x))
	{
		alert('function:changeDecimal->parameter error');
		return false;
	}
	f_x = Math.round(f_x * Math.pow(10,length))/Math.pow(10,length);
	
	return f_x;
}

//返回父li的dom
function getPicDom(dom){
	var treeDom = dom;
	while (treeDom.tagName.toLowerCase() != "li" || treeDom.className != "picture")
	{
		treeDom = treeDom.parentNode;
		if (treeDom == undefined)
		{
			alert("父图像dom查询失败");
			return null;
		}
	}
	return treeDom;
}

//返回li的索引号
function Index(obj){
    var lis=obj.parentNode.getElementsByTagName(obj.tagName);
    for(var o=0;o<lis.length;o++){
        if(lis[o]==obj) return o;
    }
}

//修改范围后面的数字
function changeRangeNum(rangeDom, suffix, prefix){
	if(suffix == undefined) suffix="";
	if(prefix == undefined) prefix="";
	var numdomClassName = rangeDom.className + "-num";
	//numdom = rangeDom.parentNode.parentNode.getElementsByClassName(numdomClassName).item(0);
	numdom = rangeDom.parentNode.nextSibling;
	numdom.innerHTML = prefix.toString() + rangeDom.value.toString() + suffix.toString();
	
}

//修改DPI后面的数字
function convertDpiNum(picDom){
	var dpi_mod = picDom.getElementsByClassName("dpi-mod").item(0);
	var dpi_num = picDom.getElementsByClassName("dpi-num").item(0);
	var picIndex = Index(picDom);
	var dpi = picsa[picIndex].dpix;
	var dpi_mod_index = parseInt(dpi_mod.value);
	switch (dpi_mod_index)
	{
	case 0:
	  dpi_num.value = dpi;
	  dpi_num.step = 1;
	  break;
	case 1:
	  dpi_num.value = dpi / 39.37;
	  dpi_num.step = 0.01;
	  break;
	case 2:
	  dpi_num.value = 1e6 / dpi;
	  dpi_num.step = 0.01;
	  break;
	}
}

//修改DPI
function changeDpiNum(picDom){
	var dpi_mod_dom = picDom.getElementsByClassName("dpi-mod").item(0);
	var dpi_num_dom = picDom.getElementsByClassName("dpi-num").item(0);
	var picIndex = Index(picDom);
	var pic = picsa[picIndex];
	var dpi_mod_index = parseInt(dpi_mod_dom.value);
	var dpi_num_this = parseFloat(dpi_num_dom.value);
	switch (dpi_mod_index)
	{
	case 0:
	  pic.dpix = dpi_num_this;
	  pic.dpiy = dpi_num_this;
	  break;
	case 1:
	  pic.dpix = dpi_num_this * 39.37;
	  pic.dpiy = dpi_num_this * 39.37;
	  break;
	case 2:
	  pic.dpix = 1e6 / dpi_num_this;
	  pic.dpiy = 1e6 / dpi_num_this;
	  break;
	}
}

//修改预览图大小
function changeThumbsSize(){
	var costomCSS = document.getElementById("custom-css");
	var thumbsWidth = document.getElementsByClassName("thumbs-width").item(0);
	var thumbsHeight = document.getElementsByClassName("thumbs-height").item(0);
	var csstext = "";
	csstext += ".draw-canvas";
	csstext += "{";
	csstext += "max-width: " + thumbsWidth.value + "px;";
	csstext += "max-height: " + thumbsHeight.value + "px;";
	csstext += "}";
	costomCSS.innerHTML = csstext;
}

window.onload = function(){
	const body = document.body;
	body.ondragenter = function(event){
		event.preventDefault();
		return false;
	};
	body.ondragover = function(event){
		event.preventDefault();
		return false;
	};
	body.ondrop = function(event){
		dropIt(event)
	};
};