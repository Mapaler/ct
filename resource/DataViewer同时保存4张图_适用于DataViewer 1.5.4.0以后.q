[General]
SyntaxVersion=2
BeginHotkey=121
BeginHotkeyMod=0
PauseHotkey=0
PauseHotkeyMod=0
StopHotkey=123
StopHotkeyMod=0
RunOnce=1
EnableWindow=
MacroID=03f4fbfe-bfed-4c0c-9bfc-d7eb06f60d4e
Description=DataViewerͬʱ����4��ͼ
Enable=1
AutoRun=0
[Repeat]
Type=0
Number=1

[Script]
Public Declare Function GetMenu Lib "user32.dll" (ByVal hwnd As Long) As Long
Public Declare Function GetSubMenu Lib "user32.dll" (ByVal hMenu As Long, ByVal nPos As Long) As Long
Public Declare Function GetMenuItemID Lib "user32.dll" (ByVal hMenu As Long, ByVal nPos As Long) As Long
Public Declare Function SendMessage Lib "user32" Alias "SendMessageW" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Any) As Long
Public Declare Function PostMessage Lib "user32" Alias "PostMessageW" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
'Public Declare Function GetWindow Lib "user32" (ByVal hwnd As Long, ByVal wCmd As Long) As Long
'Public Declare Function FindWindowEx Lib "user32" Alias "FindWindowExA" (ByVal hWnd1 As Long, ByVal hWnd2 As Long, ByVal lpsz1 As String, ByVal lpsz2 As String) As Long

Const DelayTime = 300 '��ʱ���룬���ݵ��Է�Ӧ�ٶȵ���

Const BM_CLICK = &HF5
Const WM_LBUTTONDOWN = &H201
Const WM_LBUTTONUP = &H202
Const WM_SETTEXT = &HC
Const WM_CLOSE = &H10
Const WM_COMMAND = &H111
Const WM_SETFOCUS = &H7

Const GW_CHILD = 5
Const GW_HWNDFIRST = 0
Const GW_HWNDNEXT = 2

DeskTopPath = Plugin.SysEx.GetDir(4)'�������·��
FolderPath = DeskTopPath & "\DataViewer_2D_Picture"
Plugin.File.CreateFolder FolderPath
Main(FolderPath) 

Function Main(Path)
	Dim WHwnd,Title
	WHwnd = Plugin.Window.Foreground() '��ȡ��ǰ���ھ��
	Title = Plugin.Window.GetText(WHwnd) 
	
	If InStr(Title, "DataViewer") <> 1 Then 
		'MsgBox "��ǰ���ڲ���DataViewer", vbInformation, "�������"
		TracePrint "��ǰ���ڲ���DataViewer"
		'ExitScript
		WHwnd = Plugin.Window.Find("SkyScan DataViewer",0) '��ȡ��̨DataViewer���ھ��
		Title = Plugin.Window.GetText(WHwnd) 
	End If
	If WHwnd = 0 Then 
		MessageBox "δ�ҵ�DataViewer����"
		ExitScript
	End If
	Dim MHwnd,SMHwnd,SMHwnd2
	MHwnd = GetMenu(WHwnd)'����ܲ˵����
	SMHwnd = GetSubMenu(MHwnd, 0)'���һ���Ӳ˵����
	SMHwnd2 = GetSubMenu(SMHwnd, 17)'��ȡ�����Ӳ˵����
	
	'����ͼƬ����·����ǰ׺��
	Dim t,SavePrefix
	t = Now()
	SavePrefix = Path & "\" & _
		Mid(Title, Len("DataViewer - ") + 1) & "_" & _
		add0(Year(t),4) & "-" & add0(Month(t),2) & "-" & add0(Day(t),2) & "_" & _
		add0(Hour (t),2) & "-" & add0(Minute(t),2) & "-" & add0(Second(t),2) & "_"
	Call savePic(WHwnd, SMHwnd2, SavePrefix, 0)
	Call savePic(WHwnd, SMHwnd2, SavePrefix, 1)
	Call savePic(WHwnd, SMHwnd2, SavePrefix, 2)
	Call savePic(WHwnd, SMHwnd2, SavePrefix, 8)
End Function
'�ṩ���ڡ��˵������͵ڼ�������ͼ��ť
Function savePic(hWindow, hSubMenu, pSavePrefix, pIndex)
	MIHwnd = GetMenuItemID(hSubMenu, 2 + pIndex) '��ȡ����ͼƬ��ť���
	PostMessage hWindow, WM_COMMAND, MIHwnd, 0'���������˵�
	Delay DelayTime
	
	Dim SWHwnd
	Do
		SWHwnd = Plugin.Window.FindEx(0, SWHwnd, "#32770", 0)'���洰�ڸ�����Ϊ0��ȫ������"#32770"���
		If Plugin.Window.GetParentWindow(SWHwnd) = hWindow Then '����������DataViewer���Ǳ��洰��/����ת���洰��
			TracePrint "��ñ���/��ת���洰����Ϊ " & Hex(SWHwnd) & "  " & Plugin.Window.GetText(SWHwnd)
			Exit Do
		End If
	Loop Until SWHwnd = 0
	If InStr(Plugin.Window.GetText(SWHwnd),"Attention") > 0 Then '����ת���洰�ڻ�����ͼ����
		BHwnd = Plugin.Window.FindEx(SWHwnd, 0, "Button", 0)
		If InStr(Plugin.Window.GetText(SWHwnd), "!") > 0 Then '������ͼ����
			BHwnd = Plugin.Window.FindEx(SWHwnd, BHwnd, "Button", 0)
		End If
		TracePrint "������/��ť " & Hex(BHwnd)
		SendMessage BHwnd, BM_CLICK, 0, 0
		Delay DelayTime
		SWHwnd = 0
		Do
			SWHwnd = Plugin.Window.FindEx(0, SWHwnd, "#32770", 0)'���洰�ڸ�����Ϊ0��ȫ������"#32770"���
			If Plugin.Window.GetParentWindow(SWHwnd) = hWindow Then '����������DataViewer���Ǳ��洰��
				TracePrint "��ñ��洰����Ϊ " & Hex(SWHwnd) & "  " & Plugin.Window.GetText(SWHwnd)
				Exit Do
			End If
		Loop Until SWHwnd = 0
	End If
	
	If SWHwnd = 0 Then
		TracePrint "δ�ҵ����洰��"
		Exit Function
	End If
	
	PHwnd = Plugin.Window.FindEx(SWHwnd, 0, "DUIViewWndClassName", 0)
	PHwnd = Plugin.Window.FindEx(PHwnd, 0, "DirectUIHWND", 0)
	PHwnd = Plugin.Window.FindEx(PHwnd, 0, "FloatNotifySink", 0)
	PHwnd = Plugin.Window.FindEx(PHwnd, 0, "ComboBox", 0)
	PHwnd = Plugin.Window.FindEx(PHwnd, 0, "Edit", 0)
	TracePrint "��ַ����Ϊ " & Hex(PHwnd) & "  " & Plugin.Window.GetTextEx(PHwnd,1)
	Dim SavePath, ModeName
	Select Case pIndex
		Case 0
			ModeName = "X-Z"
		Case 1
			ModeName = "Z-Y"
		Case 2
			ModeName = "X-Y"
		Case 8
			ModeName = "Screen"
	End Select
	SavePath = pSavePrefix & ModeName & ".bmp"
	Plugin.Window.SendString PHwnd,"  " & SavePath '�滻����
	'SendMessage PHwnd, WM_SETTEXT, 0, SavePath
	TracePrint "���浽 " & SavePath
	
	Delay DelayTime
	BHwnd = 0
	BHwnd = Plugin.Window.FindEx(SWHwnd, 0, "Button", 0) '���水ť
	TracePrint "���水ť���Ϊ " & Hex(BHwnd) & "  " & Plugin.Window.GetText(BHwnd)
	PostMessage BHwnd, BM_CLICK, 0, 0'���±���
	
	Delay DelayTime
	'���渲��ѯ�ʴ���
	SAWHwnd = 0	
	Do
		SAWHwnd = Plugin.Window.FindEx(0, SAWHwnd, "#32770", 0)'���洰�ڸ�����Ϊ0��ȫ������"#32770"���
		If Plugin.Window.GetParentWindow(SAWHwnd) = SWHwnd Then '����������DataViewer���Ǳ��洰��/����ת���洰��
			TracePrint "���ȷ�����Ϊ���ھ��Ϊ " & Hex(SAWHwnd) & "  " & Plugin.Window.GetText(SAWHwnd)
			Exit Do
		End If
	Loop Until SAWHwnd = 0
	If SAWHwnd <> 0 Then 
		BFHwnd = 0
		BFHwnd = Plugin.Window.FindEx(SAWHwnd, 0, "DirectUIHWND", 0)
		BHwnd = 0
		BHwnd = Plugin.Window.FindEx(BFHwnd, BHwnd, "CtrlNotifySink", 0)
		BHwnd = Plugin.Window.FindEx(BFHwnd, BHwnd, "CtrlNotifySink", 0)
		BHwnd = Plugin.Window.FindEx(BFHwnd, BHwnd, "CtrlNotifySink", 0)
		BHwnd = Plugin.Window.FindEx(BFHwnd, BHwnd, "CtrlNotifySink", 0)
		BHwnd = Plugin.Window.FindEx(BFHwnd, BHwnd, "CtrlNotifySink", 0)
		BHwnd = Plugin.Window.FindEx(BFHwnd, BHwnd, "CtrlNotifySink", 0)
		BHwnd = Plugin.Window.FindEx(BFHwnd, BHwnd, "CtrlNotifySink", 0)
		BHwnd = Plugin.Window.FindEx(BHwnd, 0, "Button", 0)
		TracePrint "ȷ����ť���Ϊ " & Hex(BHwnd) & "  " & Plugin.Window.GetText(BHwnd)
		SendMessage BHwnd, BM_CLICK, 0, 0'����ȷ��
		Delay DelayTime
	End If
	
	'������ɫѯ�ʴ���
	SCAWHwnd = 0
	Do
		SCAWHwnd = Plugin.Window.FindEx(0, SCAWHwnd, "#32770", 0)'���洰�ڸ�����Ϊ0��ȫ������"#32770"���
		If Plugin.Window.GetParentWindow(SCAWHwnd) = hWindow Then '����������DataViewer���Ǳ��洰��/����ת���洰��
			TracePrint "�����ɫѯ�ʴ��ھ��Ϊ " & Hex(SCAWHwnd) & "  " & Plugin.Window.GetText(SCAWHwnd)
			Exit Do
		End If
	Loop Until SCAWHwnd = 0
	If SCAWHwnd <> 0 Then 
		BHwnd = 0
		BHwnd = Plugin.Window.FindEx(SCAWHwnd, 0, "Button", 0) 'ȷ����ť
		TracePrint "ȷ����ť���Ϊ " & Hex(BHwnd) & "  " & Plugin.Window.GetText(BHwnd)
		SendMessage BHwnd, BM_CLICK, 0, 0'����ȷ��
		Delay DelayTime
	End If
End Function

'��0
Function add0(num, length)
	add0 = String(length - Len(num),"0") & num
End Function

'��������ϵİ�ť
Event frmMain.btnRun.Click
	Main(frmMain.iptDir.Text)
End Event
