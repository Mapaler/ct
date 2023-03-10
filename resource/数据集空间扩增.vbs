'====================================
'变量定义区
'====================================
Dim p_libpath,p_ncvt,roundROI,indexLength
p_libpath = parDir(WScript.ScriptFullName) '存放本脚本调用其他程序的位置
p_ncvt = p_libpath & "\nconvert.exe" 'NConvert程序路径
roundROI = True '是否为圆形ROI
indexLength = 8 '编号长度
'====================================
'初始化代码区
'====================================
Dim fso,osh
Set fso = CreateObject("Scripting.FileSystemObject")
Set osh = CreateObject("WScript.Shell")

If WScript.Arguments.Count<1 Then
	WScript.Echo "请把数据集任一编号图片拖到本脚本上运行"
	WScript.Quit
End If
If LCase(Right(WScript.FullName,11)) = "wscript.exe" Then
    osh.run "cmd /c cscript.exe //nologo """ & WScript.ScriptFullName & """ """ & WScript.Arguments(0) & """"
    WScript.quit
End If
'====================================
'函数区
'====================================
'三目运算符
Function IIf(Expression, TruePart, FalsePart)
	If Expression Then IIf = TruePart Else IIf = FalsePart
End Function
'获取路径父文件夹
Function parDir(path)
	Dim fsot
	Set fsot = CreateObject("Scripting.FileSystemObject")
	If fsot.FolderExists(path) Then
		parDir = fsot.GetParentFolderName(fsot.GetFolder(path))
	ElseIf fsot.FileExists(path) Then
		parDir = fsot.GetParentFolderName(fsot.GetFile(path))
	End If
	Set fsot = Nothing
End Function
'正则表达式搜索
Function RegExpSearch(strng, patrn) 
	Dim regEx      ' 创建变量。
	Set regEx = New RegExp         ' 创建正则表达式。
	regEx.Pattern = patrn         ' 设置模式。
	regEx.IgnoreCase = True         ' 设置是否区分大小写，True为不区分。
	regEx.Global = True         ' 设置全程匹配。
	regEx.MultiLine = True
	Set RegExpSearch  = regEx.Execute(strng)
	Set regEx = Nothing
End Function
'为数字添加前导零
Function LeadingZeroNum(number, length)
	Dim numStr
	numStr = CStr(number)
	LeadingZeroNum = String(length - Len(numStr),"0") & numStr
End Function
'转换为黑色部分的图片
Function ConvertImageToBlack(FilePath,outputPath)
	Dim wsPath
	wsPath = osh.CurrentDirectory '记录原始路径
	osh.CurrentDirectory = parDir(FilePath) '跳转到指定文件夹
	Dim command
	'转格式的命令行
	command = """" & p_ncvt & """ -gamma 0 -grey 256 -overwrite -o """ & outputPath & """ """ & fso.GetFileName(FilePath) & """"
	'WScript.Echo "命令："
	'WScript.Echo command
	Set oExec = osh.Exec(command)
	'strOut = oExec.StdOut.ReadAll()
	
	Do While oExec.StdOut.AtEndOfStream <> True
		WScript.Echo oExec.StdOut.ReadLine
	Loop
	'strErr = oExec.StdErr.ReadAll()
	
	osh.CurrentDirectory = wsPath '恢复原始路径
	
	'标准输出▼
	'ShowLog strOut
	'标准错误▼
	'WScript.Echo strErr
	
	Set oExec = Nothing
End Function
'扩增缩略图
Function ConvertSprImage(FilePath,outputPath,oldLength,newLength)
	Dim wsPath
	wsPath = osh.CurrentDirectory '记录原始路径
	osh.CurrentDirectory = parDir(FilePath) '跳转到指定文件夹
	Dim command
	'转格式的命令行
	command = """" & p_ncvt & """ -canvas 100%%%% " & Round((newLength/oldLength*100)) & "%%%% center -bgcolor 0 0 0 -dither -grey 256 -overwrite -o """ & outputPath & """ """ & fso.GetFileName(FilePath) & """"
	Set oExec = osh.Exec(command)
	
	Do While oExec.StdOut.AtEndOfStream <> True
		WScript.Echo oExec.StdOut.ReadLine
	Loop
	
	osh.CurrentDirectory = wsPath '恢复原始路径
	
	Set oExec = Nothing
End Function
'====================================
'主代码
'====================================
Dim Files
Set Files = WScript.Arguments '将参数（文件列表）存入类
If fso.FileExists(Files(0)) Then
	Set fl = fso.GetFile(Files(0))
	Dim parentFolder,ofileName,result,fnPre,fnInd,fnExt
	parentFolder = parDir(Files(0))
	osh.CurrentDirectory = parentFolder '切换工作文件夹到图片文件夹
	ofileName = fso.GetFileName(Files(0)) 'original file name
	
	Do
		Set result = RegExpSearch(ofileName,"^([^\\/:\*\?<>""\|]+)(\d{" & indexLength & "})\.(bmp|jpg|png|tif)$")
		If result.count < 1 Then
			WScript.Echo "该图片未检测到" & indexLength & "位编号"
			indexLength = indexLength - 4
		Else
			WScript.Echo "图片检测到" & indexLength & "位编号"
		End If
		If indexLength <= 0 Then WScript.Quit
	Loop Until result.count > 0 Or indexLength <= 0
	
	fnPre = result(0).SubMatches(0) 'file name prefix
	fnInd = CLng(result(0).SubMatches(1)) 'file name index
	fnExt = result(0).SubMatches(2) 'file name extension
	Set result = Nothing
	
	Dim mi,ma,minNumFile,maxNumFile
	mi = fnInd
	ma = fnInd
	'向下查找
	Do
		mi = mi - 1
		minNumFile = fnPre & LeadingZeroNum(mi,indexLength) & "." & fnExt
	Loop While fso.FileExists(minNumFile)
	mi = mi + 1
	'向上查找
	Do
		ma = ma + 1
		maxNumFile = fnPre & LeadingZeroNum(ma,indexLength) & "." & fnExt
	Loop While fso.FileExists(maxNumFile)
	ma = ma - 1
	
    Dim Img 'As ImageFile
    Set Img = CreateObject("WIA.ImageFile")
    Img.LoadFile Files(0)
    
	Dim width,height,length,newLength
	length = ma-mi+1
	width = Img.Width
	height = Img.Height
	
	Dim x
	x = MsgBox("ROI是否为圆形（或椭圆形）区域？" & vbCrLf & "（圆形区域可以减少扩增空间）", vbYesNoCancel Or vbQuestion)
	If x = vbYes Then
		roundROI = True
	ElseIf x = vbNo Then
		roundROI = False
	Else
		WScript.Echo "取消操作"
		WScript.Quit
	End If
	If roundROI Then newLength = Sqr(IIf(width>height, width, height)^2+length^2) Else newLength = Sqr(width^2+height^2+length^2)
	exLength = CLng((newLength - length)/2) '两段增加层数
	
	'WScript.Echo newLength & " " & exLength & " " & width & "x" & height & "x" & length
	Dim modeTxt
	If roundROI Then modeTxt = "圆形ROI区域" Else modeTxt = "矩形ROI区域" 
	WScript.Echo modeTxt & "需要扩增 " & exLength & " × 2 张图片，约 " & FormatNumber(2.54 / Img.HorizontalResolution * 1e1 * exLength, 2, True) & "mm × 2"
	
	Dim exPath,tempfn
	exPath = "enlarge"
	tempfn = "_blacktemp." & fnExt
	If Not fso.FolderExists(exPath) Then fso.CreateFolder(exPath)
	
	logFileName = fnPre & ".log"
	If fso.FileExists(logFileName) Then
		WScript.Echo "复制log文件"
		fso.CopyFile logFileName, exPath & "\" & logFileName, True
	End If
	
	sprFileName = fnPre & "_spr.bmp"
	If fso.FileExists(sprFileName) Then
		WScript.Echo "对缩影图进行扩增"
		ConvertSprImage sprFileName, exPath & "\" & sprFileName, length, newLength
	End If
	
	WScript.Echo "制作扩增部分纯黑图片"
	ConvertImageToBlack ofileName, exPath & "\" & tempfn
	Dim i, otTxt
	For i = 1 To exLength '复制纯黑
		fso.CopyFile exPath & "\" & tempfn, exPath & "\" & fnPre & LeadingZeroNum(i - 1,indexLength) & "." & fnExt, True
		fso.CopyFile exPath & "\" & tempfn, exPath & "\" & fnPre & LeadingZeroNum(ma + (exLength - mi) + i,indexLength) & "." & fnExt, True
		otTxt = "正在复制扩增部分 " & FormatNumber(i / exLength * 100, 2, True) & "%"
		WScript.StdOut.Write otTxt
		WScript.StdOut.Write String(LenB(otTxt),Chr(8))
	Next
	WScript.StdOut.WriteBlankLines(1)
	For i = mi To ma '复制本体
		fso.CopyFile fnPre & LeadingZeroNum(i,indexLength) & "." & fnExt, exPath & "\" & fnPre & LeadingZeroNum(i+(exLength - mi),indexLength) & "." & fnExt, True
		otTxt = "正在复制本体部分 " & FormatNumber((i - mi + 1) / (ma - mi + 1) * 100, 2, True) & "%"
		WScript.StdOut.Write otTxt
		WScript.StdOut.Write String(LenB(otTxt),Chr(8))
	Next
	WScript.StdOut.WriteBlankLines(1)
	fso.DeleteFile exPath & "\" & tempfn
	MsgBox "扩增数据集已保存到 enlarge 文件夹",vbOKOnly,"扩增成功"
End If