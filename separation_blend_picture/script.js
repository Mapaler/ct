// JavaScript Document
var blend1 = document.getElementById("blend1");
var blend2 = document.getElementById("blend2");
var bg1 = document.getElementById("bg1");
var bg2 = document.getElementById("bg2");
var src1 = document.getElementById("src1");
var colorView = document.getElementById("colorView");
var error_box = document.getElementById("error-box");
var error_count = document.getElementById("error-count");

var error1 = document.getElementById("error1");

var bg1_color = document.getElementById("bg1-color");
var bg2_color = document.getElementById("bg2-color");

var blend1_Cot = blend1.getContext("2d");
var blend2_Cot = blend2.getContext("2d");
var bg1_Cot = bg1.getContext("2d");
var bg2_Cot = bg2.getContext("2d");
var src1_Cot = src1.getContext("2d");
var error1_Cot = error1.getContext("2d");

/*
//debug
var blend1_img = document.getElementById("blend1-img");
var blend2_img = document.getElementById("blend2-img");
var bg1_img = document.getElementById("bg1-img");
var bg2_img = document.getElementById("bg2-img");

blend1_Cot.drawImage(blend1_img,0,0);
blend2_Cot.drawImage(blend2_img,0,0);
bg1_Cot.drawImage(bg1_img,0,0);
bg2_Cot.drawImage(bg2_img,0,0);
*/

var minWidth = 0;
var minHeight = 0;
var errorPixcel = 0;

function dropIt(e,cavans,bgColor) {  
   imagesSelected(e.dataTransfer.files,cavans,bgColor); 
   e.stopPropagation();  
   e.preventDefault();   
}

function imagesSelected(myFiles,cavans,bgColor)
{ //图片背景填充
	var f = myFiles[0];

    var imageReader = new FileReader();
	imageReader.onload = (function(aFile,aCavans) {
      return function(e) {
		var imgbin = e.target.result;
		
		//建立一个新的图片到内存中
		var img = new Image;
		img.src = window.URL.createObjectURL(aFile);
		
		//图片加载成功时画图
		img.onload=function(){
			aCavans.width = img.width;
			aCavans.height = img.height;
			var aCavans_Cot = aCavans.getContext("2d");
			aCavans_Cot.clearRect(0,0,aCavans.width,aCavans.height);
			aCavans_Cot.drawImage(img,0,0);
			if (bgColor)
			{
				var aCavans_Data = aCavans_Cot.getImageData(0, 0, 1, 1); //获取左上角颜色
				bgColor.value = rgbToHex(aCavans_Data.data[0],aCavans_Data.data[1],aCavans_Data.data[2]); //转换为16进制字符串
				bgColor.onchange(); //执行改编颜色的命令
			}
		};
      };
    })(f,cavans);
	imageReader.readAsArrayBuffer(f);
}

function rgbToHex(r,g,b)
{ //RGB颜色转换为16进制字符串
	function add0(s)
	{
		return s.length > 1? s : "0" + s;
	}
	return "#" + add0(r.toString(16)) + add0(g.toString(16)) + add0(b.toString(16));
}

function colorSelected(color,cavans,fcavans)
{ //纯色填充
	cavans.width = fcavans.width;
	cavans.height = fcavans.height;
	var cavans_Cot = cavans.getContext("2d");
	
	cavans_Cot.clearRect(0,0,cavans.width,cavans.height); //清空画布
	cavans_Cot.fillStyle = color;
	cavans_Cot.fillRect(0, 0, cavans.width, cavans.height);
}

function getColor(colorDom,cavans)
{ //从图中取色
	var scaleX = cavans.width / cavans.offsetWidth;
	var scaleY = cavans.height / cavans.offsetHeight;
	
	function removeEvent(cavansDom)
	{
		cavansDom.classList.remove("tubularis");
		colorView.style.display = "none";
		cavansDom.onmousemove = null;
		cavansDom.onclick = null;
		cavansDom.onmousedown = null;
	}
	
	cavans.classList.add("tubularis");
	cavans.onmousemove = function(e)
	{
		var cx = e.layerX * scaleX;
		var cy = e.layerY * scaleY;
		var cavans_Cot = this.getContext("2d");
		var cavans_Data = cavans_Cot.getImageData(cx, cy, 1, 1); //获取颜色
		var pcolor = rgbToHex(cavans_Data.data[0],cavans_Data.data[1],cavans_Data.data[2]);
		colorView.innerHTML = "R:" + cavans_Data.data[0] + ";G:" + cavans_Data.data[1] + ";B:" + cavans_Data.data[2] + "<br>" + pcolor;
		colorView.style.display = "block";
		colorView.style.backgroundColor = pcolor;
		colorView.style.left = (e.clientX + 30) + "px";
		colorView.style.top = (e.clientY + 15) + "px";
		//debug显示轨迹
		//cavans_Cot.fillStyle="red";
		//cavans_Cot.fillRect(cx,cy,5,5);
	}
	cavans.onmouseout = function(e)
	{
		colorView.style.display = "none";
	}
	cavans.onclick = function(e)
	{
		var cx = e.layerX * scaleX;
		var cy = e.layerY * scaleY;
		var cavans_Cot = cavans.getContext("2d");
		var cavans_Data = cavans_Cot.getImageData(cx, cy, 1, 1); //获取颜色
		colorDom.value = rgbToHex(cavans_Data.data[0],cavans_Data.data[1],cavans_Data.data[2]); //转换为16进制字符串
		colorDom.onchange(); //执行改编颜色的命令
		
		removeEvent(this);
	}
	cavans.onmousedown = function(e)
	{
		//0-左键，1-中键，2-右键
		if(e.button == 1 || e.button == 2){
			removeEvent(this);
		}
	}
}

function run()
{
	//获取最小的宽高，避免超出数据。
	minWidth = Math.min.apply(null, [blend1.width,blend2.width,bg1.width,bg2.width]);
	minHeight = Math.min.apply(null, [blend1.height,blend2.height,bg1.height,bg2.height]);
	
	src1.width = minWidth;
	src1.height = minHeight;
	error1.width = minWidth;
	error1.height = minHeight;
	
	src1_Cot.clearRect(0,0,src1.width,src1.height); //清空画布
	error1_Cot.clearRect(0,0,src1.width,src1.height);
	
	var blend1_Data = blend1_Cot.getImageData(0, 0, minWidth, minHeight);
	var blend2_Data = blend2_Cot.getImageData(0, 0, minWidth, minHeight);
	var bg1_Data = bg1_Cot.getImageData(0, 0, minWidth, minHeight);
	var bg2_Data = bg2_Cot.getImageData(0, 0, minWidth, minHeight);
	var src1_Data = src1_Cot.getImageData(0, 0, minWidth, minHeight);
	var error1_Data = src1_Cot.getImageData(0, 0, minWidth, minHeight);
	
	calc1(blend1_Data.data,blend2_Data.data,bg1_Data.data,bg2_Data.data,src1_Data.data,error1_Data.data);
	
	src1_Cot.putImageData(src1_Data,0,0); //画分离图
	if (errorPixcel > 0)
	{
		error1_Cot.putImageData(error1_Data,0,0); //画错误图
		error_box.style.display = "inline";
		error_count.innerHTML = "共有" + errorPixcel + "像素背景色相同";
	}else
	{
		error_box.style.display = "none";
		error_count.innerHTML = "没有错误";
	}
}

function calc1(blend1, blend2, bg1, bg2, blank, error1)
{ //混合分离计算函数
	errorPixcel = 0;
    for (var i = 0,bg1_len = bg1.length; i < bg1_len; i+=4)
    {
        //+0 = r
        //+1 = g
        //+2 = b
        //+3 = a
 		
		for (var p = 0 ; p < 3 ; p++){ //背景色RGB三种颜色都循环一遍
			if (bg1[i+p] == bg2[i+p]) //如果当前通道颜色相同
			{
				if (p>=2)
				{ //如果三种通道都相同，生成错误图该点纯红色
					error1[i] = 255;
					error1[i+1] = 0;
					error1[i+2] = 0;
					error1[i+3] = 255;
					errorPixcel++; //错误统计+1
					break;
				}
				continue;
			}
	 
			var alpha = 1 - (blend1[i+p] - blend2[i+p]) / (bg1[i+p] - bg2[i+p]);
			blank[i+3] = alpha * 255;
			for (var j = 0; j <= 2; j++)
			{
				if (alpha == 0)
					blank[i+j] = 255;
				else
					blank[i+j] = (blend1[i+j] + blend2[i+j] - (1 - alpha) * (bg1[i+j] + bg2[i+j])) / 2 / alpha;
			}
		}
    }
 
    return blank;
}